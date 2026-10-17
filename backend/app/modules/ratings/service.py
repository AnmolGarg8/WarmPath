import uuid
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional, Tuple
from sqlalchemy import select, update, func, desc
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.errors import AppError
from app.core.ports import ports
from app.core.events import (
    event_bus,
    RatingSubmittedPayload,
    BandChangedPayload,
    DisputeOpenedPayload,
    DisputeResolvedPayload
)
from app.modules.ratings.models import (
    SessionRating,
    RequestQualityRating,
    GiverBandProfile,
    SessionDispute
)

class RatingsService:
    @staticmethod
    def calculate_smoothed_average(ratings_with_weights: List[Tuple[int, float]]) -> Tuple[float, int]:
        prior_mean = settings.PRIOR_MEAN  # 4.0
        prior_weight = float(settings.PRIOR_WEIGHT)  # 5.0
        
        weighted_sum = sum(stars * weight for stars, weight in ratings_with_weights)
        total_weight = sum(weight for _, weight in ratings_with_weights)
        
        smoothed = (prior_mean * prior_weight + weighted_sum) / (prior_weight + total_weight)
        return round(smoothed, 2), len(ratings_with_weights)

    @staticmethod
    def evaluate_band(
        current_band: str,
        smoothed_avg: float,
        rated_count: int,
        completion_rate: float
    ) -> str:
        # Changes only permitted after at least 5 rated sessions
        if rated_count < settings.MIN_RATED_SESSIONS_BAND:
            return "Rising"

        # Thresholds from settings
        trusted_thresh = settings.TRUSTED_RATING_THRESHOLD  # 4.2
        trusted_min_n = settings.TRUSTED_MIN_SESSIONS        # 5
        top_thresh = settings.TOP_RATED_THRESHOLD           # 4.6
        top_min_n = settings.TOP_RATED_MIN_SESSIONS          # 10
        top_comp = settings.TOP_RATED_MIN_COMPLETION_RATE    # 0.90

        # Hysteresis buffer to avoid rapid toggling: 0.05
        buffer = 0.05

        if current_band == "Top Rated":
            # Demote only if drops below (threshold - buffer)
            if smoothed_avg >= (top_thresh - buffer) and rated_count >= top_min_n and completion_rate >= (top_comp - 0.02):
                return "Top Rated"
            elif smoothed_avg >= (trusted_thresh - buffer) and rated_count >= trusted_min_n:
                return "Trusted"
            else:
                return "Rising"

        elif current_band == "Trusted":
            if smoothed_avg >= top_thresh and rated_count >= top_min_n and completion_rate >= top_comp:
                return "Top Rated"
            elif smoothed_avg < (trusted_thresh - buffer):
                return "Rising"
            else:
                return "Trusted"

        else:  # Rising
            if smoothed_avg >= top_thresh and rated_count >= top_min_n and completion_rate >= top_comp:
                return "Top Rated"
            elif smoothed_avg >= trusted_thresh and rated_count >= trusted_min_n:
                return "Trusted"
            else:
                return "Rising"

    @staticmethod
    async def get_or_create_profile(session: AsyncSession, giver_id: uuid.UUID) -> GiverBandProfile:
        stmt = select(GiverBandProfile).where(GiverBandProfile.giver_id == giver_id)
        profile = (await session.execute(stmt)).scalar_one_or_none()
        if not profile:
            profile = GiverBandProfile(
                giver_id=giver_id,
                current_band="Rising",
                smoothed_average=settings.PRIOR_MEAN,
                rated_sessions_count=0,
                completed_sessions_count=0,
                total_booked_sessions_count=0,
                giver_no_show_count=0,
                completion_rate=1.0
            )
            session.add(profile)
            await session.commit()
            await session.refresh(profile)
        return profile

    @staticmethod
    async def evaluate_integrity(
        session: AsyncSession,
        student_id: uuid.UUID,
        giver_id: uuid.UUID,
        stars: int
    ) -> Tuple[float, bool, List[str]]:
        weight = 1.0
        flags = []

        # 1. Check repeated rating pairs between the same two accounts
        stmt = select(func.count(SessionRating.id)).where(
            SessionRating.student_id == student_id,
            SessionRating.giver_id == giver_id
        )
        count = (await session.execute(stmt)).scalar() or 0
        if count >= 3:
            weight *= 0.5
            flags.append("frequent_pair_rating")

        # 2. Check 5-star burst or 1-star attack
        one_day_ago = datetime.now(timezone.utc) - timedelta(days=1)
        recent_stmt = select(SessionRating.stars).where(
            SessionRating.giver_id == giver_id,
            SessionRating.created_at >= one_day_ago
        )
        recent_ratings = (await session.execute(recent_stmt)).scalars().all()
        if len(recent_ratings) >= 5:
            if all(s == 1 for s in recent_ratings):
                weight *= 0.3
                flags.append("burst_low_rating_spike")
            elif all(s == 5 for s in recent_ratings):
                weight *= 0.5
                flags.append("burst_high_rating_spike")

        # 3. Check student rating history count (new account without prior history)
        history_stmt = select(func.count(SessionRating.id)).where(SessionRating.student_id == student_id)
        total_history = (await session.execute(history_stmt)).scalar() or 0
        if total_history == 0 and stars == 5:
            weight *= 0.8
            flags.append("first_time_rater")

        is_suspicious = len(flags) > 0
        return round(weight, 2), is_suspicious, flags

    @staticmethod
    async def recompute_giver_band(session: AsyncSession, giver_id: uuid.UUID):
        profile = await RatingsService.get_or_create_profile(session, giver_id)
        
        # Fetch all ratings
        stmt = select(SessionRating.stars, SessionRating.weight).where(SessionRating.giver_id == giver_id)
        res = await session.execute(stmt)
        ratings = [(r.stars, r.weight) for r in res.all()]

        smoothed_avg, rated_count = RatingsService.calculate_smoothed_average(ratings)
        old_band = profile.current_band

        # Calculate completion rate
        total = max(profile.total_booked_sessions_count, profile.completed_sessions_count)
        if total > 0:
            comp_rate = max(0.0, min(1.0, (total - profile.giver_no_show_count) / total))
        else:
            comp_rate = 1.0

        new_band = RatingsService.evaluate_band(old_band, smoothed_avg, rated_count, comp_rate)

        profile.smoothed_average = smoothed_avg
        profile.rated_sessions_count = rated_count
        profile.completion_rate = round(comp_rate, 2)

        if new_band != old_band:
            profile.current_band = new_band
            profile.last_band_change = datetime.now(timezone.utc)
            await event_bus.publish(
                session,
                "band.changed",
                BandChangedPayload(
                    giver_id=str(giver_id),
                    old_band=old_band,
                    new_band=new_band,
                    smoothed_average=smoothed_avg
                )
            )

        await session.commit()
        await session.refresh(profile)
        return profile

    @staticmethod
    async def submit_student_rating(
        session: AsyncSession,
        session_id: uuid.UUID,
        student_id: uuid.UUID,
        giver_id: uuid.UUID,
        stars: int,
        reason: Optional[str],
        tags: List[str]
    ) -> SessionRating:
        # Check if already rated
        check_stmt = select(SessionRating).where(SessionRating.session_id == session_id)
        existing = (await session.execute(check_stmt)).scalar_one_or_none()
        if existing:
            raise AppError(code="already_rated", message="This session has already been rated", status_code=400)

        # Integrity check
        weight, is_suspicious, flags = await RatingsService.evaluate_integrity(session, student_id, giver_id, stars)

        # Safety scan reason if present
        safety_approved = True
        if reason:
            scan = await ports.safety.scan_text(reason, str(student_id), context="rating_reason")
            if scan.get("action") == "block":
                raise AppError(code="reason_blocked", message="Review reason flagged by safety filters", status_code=400)
            elif scan.get("action") == "review":
                safety_approved = False

        rating = SessionRating(
            session_id=session_id,
            student_id=student_id,
            giver_id=giver_id,
            stars=stars,
            reason=reason,
            tags=tags,
            weight=weight,
            is_suspicious=is_suspicious,
            suspicion_flags=flags,
            safety_approved=safety_approved
        )
        session.add(rating)
        await session.flush()

        await event_bus.publish(
            session,
            "rating.submitted",
            RatingSubmittedPayload(
                session_id=str(session_id),
                giver_id=str(giver_id),
                student_id=str(student_id),
                rating=stars
            )
        )
        await session.commit()
        await session.refresh(rating)

        # Recompute band
        await RatingsService.recompute_giver_band(session, giver_id)
        return rating

    @staticmethod
    async def submit_request_quality(
        session: AsyncSession,
        session_id: uuid.UUID,
        giver_id: uuid.UUID,
        student_id: uuid.UUID,
        stars: int,
        note: Optional[str]
    ) -> RequestQualityRating:
        stmt = select(RequestQualityRating).where(RequestQualityRating.session_id == session_id)
        if (await session.execute(stmt)).scalar_one_or_none():
            raise AppError(code="already_rated", message="Request quality already submitted", status_code=400)

        rq = RequestQualityRating(
            session_id=session_id,
            giver_id=giver_id,
            student_id=student_id,
            stars=stars,
            note=note
        )
        session.add(rq)
        await session.commit()
        await session.refresh(rq)
        return rq

    @staticmethod
    async def open_dispute(
        session: AsyncSession,
        session_id: uuid.UUID,
        user_id: uuid.UUID,
        reason: str,
        details: str
    ) -> SessionDispute:
        stmt = select(SessionDispute).where(SessionDispute.session_id == session_id)
        if (await session.execute(stmt)).scalar_one_or_none():
            raise AppError(code="dispute_exists", message="Dispute already active for this session", status_code=400)

        dispute = SessionDispute(
            session_id=session_id,
            opened_by_user_id=user_id,
            reason=reason,
            details=details,
            status="open"
        )
        session.add(dispute)
        await session.flush()

        await event_bus.publish(
            session,
            "dispute.opened",
            DisputeOpenedPayload(
                dispute_id=str(dispute.id),
                session_id=str(session_id),
                opened_by_user_id=str(user_id),
                reason=reason
            )
        )
        await session.commit()
        await session.refresh(dispute)
        return dispute

    @staticmethod
    async def resolve_dispute(
        session: AsyncSession,
        dispute_id: uuid.UUID,
        moderator_id: uuid.UUID,
        decision: str,
        note: Optional[str]
    ) -> SessionDispute:
        stmt = select(SessionDispute).where(SessionDispute.id == dispute_id).with_for_update()
        dispute = (await session.execute(stmt)).scalar_one_or_none()
        if not dispute:
            raise AppError(code="dispute_not_found", message="Dispute not found", status_code=404)

        dispute.status = "resolved"
        dispute.decision = decision
        dispute.resolution_note = note
        dispute.resolved_by = moderator_id
        dispute.resolved_at = datetime.now(timezone.utc)

        await event_bus.publish(
            session,
            "dispute.resolved",
            DisputeResolvedPayload(
                dispute_id=str(dispute.id),
                outcome=decision,
                resolved_by=str(moderator_id)
            )
        )
        await session.commit()
        await session.refresh(dispute)
        return dispute
