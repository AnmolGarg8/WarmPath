"""
backend/app/modules/trust/service.py - Business logic for Trust, Safety, and Moderation.
"""

import hashlib
import json
import re
from dataclasses import dataclass
from datetime import UTC, datetime, timedelta
from typing import Any
from uuid import UUID, uuid4

from fastapi import UploadFile
from sqlalchemy import func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import joinedload

import app.core.redis as core_redis
from app.core.config import settings
from app.core.db import ApprovedMember, User, VerificationRequest
from app.core.errors import AppError
from app.core.events import (
    ReportFiledPayload,
    TrustLevelChangedPayload,
    UserVerifiedPayload,
    event_bus,
)
from app.core.ports import SafetyPort, TrustPort
from app.modules.trust.models import AuditLog, Block, FlaggedItem, Report
from app.modules.trust.schemas import (
    ApprovedMembersUploadResponse,
    CreateBlockRequest,
    CreateReportRequest,
    MeTrustResponse,
    ModerationItem,
    ModerationQueueResponse,
    VerificationQueueItem,
    VerificationQueueResponse,
)


def _ensure_utc(dt: datetime | None) -> datetime:
    if dt is None:
        return datetime.min.replace(tzinfo=UTC)
    if dt.tzinfo is None:
        return dt.replace(tzinfo=UTC)
    return dt


# --- 1. Trust Score & Pure Level Computation ---

@dataclass
class TrustFactors:
    verification_level: str
    completed_sessions: int = 0
    total_sessions: int = 0
    account_age_days: int = 0
    upheld_reports: int = 0
    is_admin_restricted: bool = False


def compute_trust_level(factors: TrustFactors) -> str:
    """
    Pure deterministic function to compute trust level.
    Never exposed as a numeric ranking.

    Formula & Thresholds:
    - 'restricted': if admin restricted or >= 2 upheld reports.
    - 'new': if verification_level != 'verified'.
    - 'established': if verified, account age >= 14 days, completed >= 5 sessions,
      completion rate >= 90%, and 0 upheld reports.
    - 'verified': verified baseline.
    """
    if factors.is_admin_restricted or factors.upheld_reports >= 2:
        return "restricted"

    if factors.verification_level != "verified":
        return "new"

    completion_rate = (
        factors.completed_sessions / factors.total_sessions
        if factors.total_sessions > 0
        else (1.0 if factors.completed_sessions > 0 else 0.0)
    )

    if (
        factors.account_age_days >= 14
        and factors.completed_sessions >= 5
        and completion_rate >= 0.90
        and factors.upheld_reports == 0
    ):
        return "established"

    return "verified"


DAILY_REQUEST_LIMITS = {
    "restricted": 1,
    "new": 3,
    "verified": 10,
    "established": 25,
}


# --- 2. Safety Rules Engine & Text Scanner ---

PHONE_REGEX = re.compile(
    r"(?:(?:\+|0{0,2})91[\s-]?)?[6-9]\d{4}[\s-]?\d{5}\b|\b[6-9]\d{9}\b"
)
SHORTENER_REGEX = re.compile(
    r"\b(?:https?://)?(?:bit\.ly|tinyurl\.com|t\.co|goo\.gl|ow\.ly|is\.gd|buff\.ly|cutt\.ly|rb\.gy)/\S+",
    re.IGNORECASE,
)

FEE_PATTERNS = [
    re.compile(r"registration\s*fee", re.IGNORECASE),
    re.compile(r"security\s*deposit", re.IGNORECASE),
    re.compile(r"pay\s*to\s*get\s*(?:the\s*)?job", re.IGNORECASE),
    re.compile(r"processing\s*fee", re.IGNORECASE),
    re.compile(r"application\s*fee", re.IGNORECASE),
    re.compile(r"refundable\s*deposit", re.IGNORECASE),
    re.compile(r"joining\s*fee", re.IGNORECASE),
    re.compile(r"training\s*fee", re.IGNORECASE),
    re.compile(r"interview\s*fee", re.IGNORECASE),
    re.compile(r"upfront\s*(?:fee|payment|money)", re.IGNORECASE),
    re.compile(r"send\s*(?:money|cash|crypto|usdt|bitcoin)", re.IGNORECASE),
    re.compile(r"wire\s*transfer", re.IGNORECASE),
]

OFF_PLATFORM_PATTERNS = [
    re.compile(r"whats?\s*app", re.IGNORECASE),
    re.compile(r"wats\s*app", re.IGNORECASE),
    re.compile(r"wa\.me", re.IGNORECASE),
    re.compile(r"wa\.link", re.IGNORECASE),
    re.compile(r"telegram", re.IGNORECASE),
    re.compile(r"t\.me", re.IGNORECASE),
    re.compile(r"tele\s*gram", re.IGNORECASE),
    re.compile(r"ping\s*(?:me\s*)?on\s*wa", re.IGNORECASE),
    re.compile(r"dm\s*(?:me\s*)?on\s*(?:wa|telegram|insta|ig)", re.IGNORECASE),
]


def normalize_for_keyword_search(text: str) -> str:
    """Deobfuscates text while preserving letter boundaries."""
    t = text.lower()
    # Leetspeak replacements
    for k, v in {"@": "a", "4": "a", "0": "o", "1": "i", "3": "e", "$": "s"}.items():
        t = t.replace(k, v)
    # Squash single-spaced sequences of letters: 'r e g i s t r a t i o n' -> 'registration'
    t = re.sub(r"(?<=\b[a-zA-Z])[.\-_\s](?=[a-zA-Z]\b)", "", t)
    # Remove dots/dashes inside words: 'w.h.a.t.s.a.p.p' -> 'whatsapp'
    t = re.sub(r"(?<=[a-zA-Z])[.\-_](?=[a-zA-Z])", "", t)
    return t


class SafetyServiceImpl(SafetyPort):
    def __init__(self, session_maker=None):
        self._session_maker = session_maker

    def get_session(self):
        if self._session_maker is not None:
            return self._session_maker()
        import app.core.db as core_db
        return core_db.async_session_maker()

    async def scan_text(
        self, text: str, sender_id: str, context: str | None = None
    ) -> dict[str, Any]:
        """
        Scans message content for scam indicators, off-platform pushes, and spam.
        Returns: {flags: [...], action: 'allow'|'warn'|'block'|'review'}
        """
        if not text or not text.strip():
            return {"flags": [], "action": "allow"}

        raw_text = text.strip()
        normalized_text = normalize_for_keyword_search(raw_text)
        flags: list[str] = []
        action = "allow"

        # 1. Scam fee detection (High severity -> BLOCK)
        for pattern in FEE_PATTERNS:
            if pattern.search(normalized_text) or pattern.search(raw_text):
                flags.append("fee_fraud")
                action = "block"
                break

        # 2. Shortened link detection (Suspicious -> BLOCK if fee present, WARN otherwise)
        if SHORTENER_REGEX.search(raw_text):
            flags.append("shortened_link")
            if action != "block":
                action = "warn"

        # 3. Off-platform contact detection (WARN)
        has_phone = bool(PHONE_REGEX.search(raw_text))
        has_chat_push = any(
            p.search(normalized_text) or p.search(raw_text) for p in OFF_PLATFORM_PATTERNS
        )

        if has_phone or has_chat_push:
            if has_phone:
                flags.append("phone_number")
            if has_chat_push:
                flags.append("off_platform_contact")
            if action not in ["block"]:
                action = "warn"

        # 4. Copy-paste outreach detection via Redis fingerprint
        try:
            r = await core_redis.get_redis()
            fingerprint = hashlib.sha256(raw_text.lower().encode()).hexdigest()
            fingerprint_key = f"ratelimit:fingerprint:{sender_id}:{fingerprint}"
            count = await r.incr(fingerprint_key)
            if count == 1:
                await r.expire(fingerprint_key, 600)
            if count >= 3:
                flags.append("copy_paste_spam")
                if action == "allow":
                    action = "warn"
        except Exception:
            pass

        # 5. Optional Gemini Classifier for uncertain edge cases
        # (Only called when rules flag uncertainty and action is not already 'block')
        if "fee_fraud" not in flags and getattr(settings, "GEMINI_API_KEY", None):
            uncertain_indicators = ["deposit", "charges", "payment", "bank", "token"]
            if any(ind in normalized_text for ind in uncertain_indicators):
                gemini_res = await self._call_gemini_classifier(raw_text, context)
                if gemini_res:
                    if gemini_res.get("action") == "block":
                        action = "block"
                        flags.extend(gemini_res.get("flags", []))
                    elif gemini_res.get("action") == "review" and action == "allow":
                        action = "review"
                        flags.extend(gemini_res.get("flags", []))

        # 6. Record flagged item in database for audit/moderation if not allowed
        if action in ["warn", "block", "review"] and sender_id:
            try:
                async with self.get_session() as session:
                    sender_uuid = UUID(sender_id) if isinstance(sender_id, str) else sender_id
                    item = FlaggedItem(
                        id=uuid4(),
                        sender_id=sender_uuid,
                        text=raw_text,
                        flags=list(set(flags)),
                        action=action,
                        context=context,
                        status="pending" if action in ["block", "review"] else "resolved",
                        created_at=datetime.now(UTC),
                    )
                    session.add(item)
                    await session.commit()
            except Exception:
                pass

        return {"flags": list(set(flags)), "action": action}

    async def _call_gemini_classifier(
        self, text: str, context: str | None
    ) -> dict[str, Any] | None:
        """Optional Gemini classifier with strict JSON output."""
        try:
            import google.generativeai as genai
            genai.configure(api_key=settings.GEMINI_API_KEY)
            model = genai.GenerativeModel(settings.GEMINI_TEXT_MODEL)
            prompt = (
                "You are a strict safety classifier for WarmPath, a student-alumni platform.\n"
                "Analyze the following text for scam attempts, fees, off-platform push, or harassment.\n"
                "Output ONLY a JSON object: {\"action\": \"allow\"|\"warn\"|\"block\"|\"review\", \"flags\": [...], \"confidence\": 0.0-1.0, \"reason\": \"...\"}\n\n"
                f"Context: {context or 'direct_message'}\n"
                f"Text: {text}\n"
            )
            response = await model.generate_content_async(prompt)
            match = re.search(r"\{.*\}", response.text, re.DOTALL)
            if match:
                return json.loads(match.group(0))
        except Exception:
            # Fall back directly to rules output; never allow on error
            pass
        return None


# --- 3. Trust Port Implementation ---

class TrustServiceImpl(TrustPort):
    def __init__(self, session_maker=None):
        self._session_maker = session_maker

    def get_session(self):
        if self._session_maker is not None:
            return self._session_maker()
        import app.core.db as core_db
        return core_db.async_session_maker()

    async def get_level(self, user_id: str) -> str:
        """Returns trust level: new|verified|established|restricted"""
        try:
            async with self.get_session() as session:
                u_id = UUID(user_id) if isinstance(user_id, str) else user_id
                res = await session.execute(select(User.trust_level).where(User.id == u_id))
                level = res.scalar_one_or_none()
                return level or "new"
        except Exception:
            return "new"

    async def can(self, user_id: str, action: str) -> dict[str, Any]:
        """
        Enforces graduated privileges and daily Redis limits per level.
        Actions: send_request, send_message, post_opportunity, host_session.
        """
        level = await self.get_level(user_id)

        if action == "send_request":
            limit = DAILY_REQUEST_LIMITS.get(level, 3)
            today_utc = datetime.now(UTC).strftime("%Y-%m-%d")
            key = f"ratelimit:requests:{user_id}:{today_utc}"
            try:
                r = await core_redis.get_redis()
                count = int(await r.get(key) or 0)
                if count >= limit:
                    return {
                        "allowed": False,
                        "reason": f"Daily request limit of {limit} reached for your trust level ({level}).",
                        "remaining": 0,
                    }
                return {
                    "allowed": True,
                    "reason": "Allowed",
                    "remaining": limit - count,
                }
            except Exception:
                return {"allowed": True, "reason": "Allowed", "remaining": limit}

        if action == "send_message":
            if level == "restricted":
                return {
                    "allowed": True,
                    "reason": "Message will be reviewed before delivery.",
                    "reviewed_first": True,
                }
            return {"allowed": True, "reason": "Allowed", "reviewed_first": False}

        if action == "post_opportunity":
            if level in ["verified", "established"]:
                return {"allowed": True, "reason": "Allowed"}
            return {
                "allowed": False,
                "reason": "Only verified or established members may post opportunities.",
            }

        if action == "host_session":
            if level in ["verified", "established"]:
                return {"allowed": True, "reason": "Allowed"}
            if level == "restricted":
                return {
                    "allowed": False,
                    "reason": "Restricted accounts are not permitted to host sessions.",
                }
            return {
                "allowed": False,
                "reason": "Account must be verified to host sessions.",
            }

        return {"allowed": False, "reason": f"Unknown action '{action}'"}

    async def is_blocked(self, user_a: str, user_b: str) -> bool:
        """Returns True if user_a has blocked user_b or user_b has blocked user_a."""
        try:
            async with self.get_session() as session:
                u_a = UUID(user_a) if isinstance(user_a, str) else user_a
                u_b = UUID(user_b) if isinstance(user_b, str) else user_b

                res = await session.execute(
                    select(Block.id).where(
                        or_(
                            (Block.blocker_id == u_a) & (Block.blocked_id == u_b),
                            (Block.blocker_id == u_b) & (Block.blocked_id == u_a),
                        )
                    )
                )
                return res.scalar_one_or_none() is not None
        except Exception:
            return False


# --- 4. Trust Module Application Service ---

class TrustService:
    @staticmethod
    async def get_me_trust(user: User, db: AsyncSession) -> MeTrustResponse:
        level = user.trust_level or "new"
        limit = DAILY_REQUEST_LIMITS.get(level, 3)
        today_utc = datetime.now(UTC).strftime("%Y-%m-%d")
        key = f"ratelimit:requests:{user.id}:{today_utc}"

        remaining = limit
        try:
            r = await core_redis.get_redis()
            used = int(await r.get(key) or 0)
            remaining = max(0, limit - used)
        except Exception:
            pass

        return MeTrustResponse(
            trust_level=level,
            verification_level=user.verification_level,
            requests_per_day_limit=limit,
            requests_per_day_remaining=remaining,
            can_post_jobs=(level in ["verified", "established"]),
            can_host_session=(level in ["verified", "established"]),
            messages_reviewed_first=(level == "restricted"),
            limits={
                "daily_requests": limit,
                "messages_reviewed": (level == "restricted"),
                "job_posting_enabled": (level in ["verified", "established"]),
            },
        )

    @staticmethod
    async def create_report(user: User, req: CreateReportRequest, db: AsyncSession) -> Report:
        if not req.target_user_id and not req.message_id and not req.request_id:
            raise AppError(
                code="invalid_report",
                message="At least one target (target_user_id, message_id, or request_id) must be provided.",
                status_code=400,
            )

        report = Report(
            id=uuid4(),
            reporter_id=user.id,
            target_user_id=req.target_user_id,
            message_id=req.message_id,
            request_id=req.request_id,
            reason=req.reason,
            details=req.details,
            status="pending",
            created_at=datetime.now(UTC),
        )
        db.add(report)
        await db.flush()

        # Publish report.filed event
        await event_bus.publish(
            db,
            "report.filed",
            ReportFiledPayload(
                report_id=str(report.id),
                reporter_id=str(user.id),
                reported_user_id=str(req.target_user_id) if req.target_user_id else "",
                reason=req.reason,
            ),
        )

        # Check for repeated reports threshold against target user
        if req.target_user_id:
            seven_days_ago = datetime.now(UTC) - timedelta(days=7)
            res = await db.execute(
                select(func.count(Report.id)).where(
                    Report.target_user_id == req.target_user_id,
                    Report.created_at >= seven_days_ago,
                )
            )
            count = res.scalar() or 0

            # If >= 3 reports in 7 days, auto-restrict target account
            if count >= 3:
                target_user_res = await db.execute(
                    select(User).where(User.id == req.target_user_id)
                )
                target_user = target_user_res.scalar_one_or_none()
                if target_user and target_user.trust_level != "restricted":
                    old_lvl = target_user.trust_level
                    target_user.trust_level = "restricted"
                    target_user.status = "restricted"

                    # Audit log for auto-restriction
                    audit = AuditLog(
                        id=uuid4(),
                        actor_id=user.id,
                        actor_email="system@warmpath.internal",
                        action="user.auto_restricted",
                        target_type="user",
                        target_id=str(target_user.id),
                        institution_id=target_user.institution_id,
                        details={"reason": f"Accumulated {count} reports within 7 days"},
                        created_at=datetime.now(UTC),
                    )
                    db.add(audit)

                    await event_bus.publish(
                        db,
                        "trust.level_changed",
                        TrustLevelChangedPayload(
                            user_id=str(target_user.id),
                            old_level=old_lvl,
                            new_level="restricted",
                            reason="Automatic restriction after multiple user reports",
                        ),
                    )

        await db.commit()
        await db.refresh(report)
        return report

    @staticmethod
    async def create_block(user: User, req: CreateBlockRequest, db: AsyncSession) -> Block:
        if user.id == req.blocked_user_id:
            raise AppError(
                code="cannot_block_self",
                message="You cannot block yourself.",
                status_code=400,
            )

        existing_res = await db.execute(
            select(Block).where(
                Block.blocker_id == user.id, Block.blocked_id == req.blocked_user_id
            )
        )
        existing = existing_res.scalar_one_or_none()
        if existing:
            return existing

        block = Block(
            id=uuid4(),
            blocker_id=user.id,
            blocked_id=req.blocked_user_id,
            reason=req.reason,
            created_at=datetime.now(UTC),
        )
        db.add(block)
        await db.commit()
        await db.refresh(block)
        return block

    @staticmethod
    async def delete_block(user: User, target_user_id: UUID, db: AsyncSession) -> None:
        result = await db.execute(
            select(Block).where(
                Block.blocker_id == user.id, Block.blocked_id == target_user_id
            )
        )
        record = result.scalar_one_or_none()
        if record:
            await db.delete(record)
            await db.commit()

    @staticmethod
    async def get_moderation_queue(
        user: User,
        status: str | None,
        item_type: str | None,
        cursor: str | None,
        limit: int,
        db: AsyncSession,
    ) -> ModerationQueueResponse:
        # Determine institution scoping: platform_admin and moderator are global; institution_admin is scoped
        is_inst_admin = (
            "institution_admin" in (user.roles or [])
            and "platform_admin" not in (user.roles or [])
            and "moderator" not in (user.roles or [])
        )

        items: list[ModerationItem] = []

        # 1. Fetch reports
        if not item_type or item_type == "report":
            stmt = select(Report).order_by(Report.created_at.desc()).limit(limit)
            if status:
                stmt = stmt.where(Report.status == status)

            if is_inst_admin and user.institution_id:
                stmt = stmt.join(User, Report.target_user_id == User.id).where(
                    User.institution_id == user.institution_id
                )

            res = await db.execute(stmt)
            for r in res.scalars().all():
                items.append(
                    ModerationItem(
                        id=str(r.id),
                        type="report",
                        status=r.status,
                        severity="high" if r.reason in ["scam", "fraud"] else "medium",
                        reporter_id=str(r.reporter_id),
                        target_user_id=str(r.target_user_id) if r.target_user_id else None,
                        reason=r.reason,
                        details=r.details,
                        created_at=_ensure_utc(r.created_at),
                    )
                )

        # 2. Fetch flagged items
        if not item_type or item_type == "flagged_message":
            stmt = select(FlaggedItem).order_by(FlaggedItem.created_at.desc()).limit(limit)
            if status:
                stmt = stmt.where(FlaggedItem.status == status)

            if is_inst_admin and user.institution_id:
                stmt = stmt.join(User, FlaggedItem.sender_id == User.id).where(
                    User.institution_id == user.institution_id
                )

            res = await db.execute(stmt)
            for f in res.scalars().all():
                items.append(
                    ModerationItem(
                        id=str(f.id),
                        type="flagged_message",
                        status=f.status,
                        severity="high" if f.action == "block" else "medium",
                        reporter_id=None,
                        target_user_id=str(f.sender_id),
                        reason=f"Safety Flagged: {', '.join(f.flags) if isinstance(f.flags, list) else f.flags}",
                        details=f.text[:200],
                        created_at=_ensure_utc(f.created_at),
                    )
                )

        items.sort(key=lambda x: _ensure_utc(x.created_at), reverse=True)
        items = items[:limit]
        next_cursor = str(items[-1].created_at.timestamp()) if len(items) == limit else None

        return ModerationQueueResponse(items=items, next_cursor=next_cursor)

    @staticmethod
    async def resolve_moderation(
        item_id: UUID,
        decision: str,
        note: str,
        admin: User,
        db: AsyncSession,
    ) -> dict[str, Any]:
        # Try finding in reports
        report_res = await db.execute(select(Report).where(Report.id == item_id))
        report = report_res.scalar_one_or_none()

        target_user = None
        if report:
            report.status = "dismissed" if decision == "dismiss" else "resolved"
            report.resolution_decision = decision
            report.resolution_note = note
            report.resolved_by_id = admin.id
            report.resolved_at = datetime.now(UTC)

            if report.target_user_id:
                u_res = await db.execute(select(User).where(User.id == report.target_user_id))
                target_user = u_res.scalar_one_or_none()
        else:
            # Check flagged_items
            flag_res = await db.execute(select(FlaggedItem).where(FlaggedItem.id == item_id))
            flagged = flag_res.scalar_one_or_none()
            if not flagged:
                raise AppError(
                    code="moderation_item_not_found",
                    message="Moderation item not found.",
                    status_code=404,
                )
            flagged.status = "resolved"
            flagged.resolved_by_id = admin.id
            flagged.resolved_at = datetime.now(UTC)

            u_res = await db.execute(select(User).where(User.id == flagged.sender_id))
            target_user = u_res.scalar_one_or_none()

        # Apply decision to target user
        if target_user:
            old_level = target_user.trust_level
            if decision == "restrict":
                target_user.trust_level = "restricted"
                target_user.status = "restricted"
            elif decision == "suspend":
                target_user.status = "suspended"
                target_user.trust_level = "restricted"
            elif decision == "ban":
                target_user.status = "deleted"
                target_user.trust_level = "restricted"

            if target_user.trust_level != old_level:
                await event_bus.publish(
                    db,
                    "trust.level_changed",
                    TrustLevelChangedPayload(
                        user_id=str(target_user.id),
                        old_level=old_level,
                        new_level=target_user.trust_level,
                        reason=f"Moderation resolution: {decision}. Note: {note}",
                    ),
                )

        # Audit log entry
        audit = AuditLog(
            id=uuid4(),
            actor_id=admin.id,
            actor_email=admin.email,
            action="moderation.resolve",
            target_type="moderation_item",
            target_id=str(item_id),
            institution_id=admin.institution_id,
            details={"decision": decision, "note": note},
            created_at=datetime.now(UTC),
        )
        db.add(audit)

        await db.commit()
        return {
            "report_id": str(item_id),
            "decision": decision,
            "note": note,
            "resolved_by": admin.email,
            "resolved_at": datetime.now(UTC),
        }

    @staticmethod
    async def get_verification_queue(
        user: User, cursor: str | None, limit: int, db: AsyncSession
    ) -> VerificationQueueResponse:
        stmt = (
            select(VerificationRequest)
            .options(joinedload(VerificationRequest.user))
            .where(VerificationRequest.status == "pending")
            .order_by(VerificationRequest.created_at.desc())
            .limit(limit)
        )

        # Scoping for institution_admin
        if (
            "institution_admin" in (user.roles or [])
            and "platform_admin" not in (user.roles or [])
            and "moderator" not in (user.roles or [])
            and user.institution_id
        ):
            stmt = stmt.join(User, VerificationRequest.user_id == User.id).where(
                User.institution_id == user.institution_id
            )

        res = await db.execute(stmt)
        requests = res.scalars().all()

        items = [
            VerificationQueueItem(
                id=req.id,
                user_id=str(req.user_id),
                user_email=req.user.email if req.user else "",
                user_full_name=req.user.full_name if req.user else "",
                kind=req.kind,
                evidence_text=req.evidence_text,
                evidence_urls=req.evidence_urls or [],
                company_name=req.company_name,
                company_registration=req.company_registration,
                status=req.status,
                created_at=_ensure_utc(req.created_at),
            )
            for req in requests
        ]

        next_cursor = str(items[-1].created_at.timestamp()) if len(items) == limit else None
        return VerificationQueueResponse(items=items, next_cursor=next_cursor)

    @staticmethod
    async def decide_verification(
        request_id: UUID,
        decision: str,
        badge: str | None,
        note: str | None,
        admin: User,
        db: AsyncSession,
    ) -> dict[str, Any]:
        res = await db.execute(
            select(VerificationRequest)
            .options(joinedload(VerificationRequest.user))
            .where(VerificationRequest.id == request_id)
        )
        req = res.scalar_one_or_none()
        if not req:
            raise AppError(
                code="verification_request_not_found",
                message="Verification request not found.",
                status_code=404,
            )

        badge_assigned = None
        if decision == "approve":
            req.status = "approved"
            user = req.user
            if user:
                user.verification_level = "verified"
                assigned_badge = badge or f"Verified {req.kind.capitalize()}"
                badges = list(user.badges or [])
                if assigned_badge not in badges:
                    badges.append(assigned_badge)
                user.badges = badges

                roles = list(user.roles or [])
                if req.kind not in roles:
                    roles.append(req.kind)
                user.roles = roles
                badge_assigned = assigned_badge

                # Disclose event to outbox
                if user.institution_id:
                    await event_bus.publish(
                        db,
                        "user.verified",
                        UserVerifiedPayload(
                            user_id=str(user.id),
                            institution_id=user.institution_id,
                            role=req.kind,
                        ),
                    )

                # Recompute trust level upon verification
                user.trust_level = compute_trust_level(
                    TrustFactors(
                        verification_level="verified",
                        account_age_days=(datetime.now(UTC) - user.created_at).days,
                    )
                )
        else:
            req.status = "rejected"

        # Record AuditLog
        audit = AuditLog(
            id=uuid4(),
            actor_id=admin.id,
            actor_email=admin.email,
            action="verification.decide",
            target_type="verification_request",
            target_id=str(request_id),
            institution_id=admin.institution_id,
            details={"decision": decision, "badge": badge_assigned, "note": note},
            created_at=datetime.now(UTC),
        )
        db.add(audit)

        await db.commit()
        return {
            "request_id": request_id,
            "decision": decision,
            "badge_assigned": badge_assigned,
            "note": note,
        }

    @staticmethod
    async def upload_approved_members(
        file: UploadFile,
        admin: User,
        target_institution_id: int | None,
        db: AsyncSession,
    ) -> ApprovedMembersUploadResponse:
        institution_id = target_institution_id or admin.institution_id
        if not institution_id:
            raise AppError(
                code="missing_institution",
                message="Institution ID is required for approved members upload.",
                status_code=400,
            )

        content = await file.read()
        text_content = content.decode("utf-8-sig", errors="ignore")
        lines = [line.strip() for line in text_content.splitlines() if line.strip()]

        if not lines:
            raise AppError(code="empty_file", message="The uploaded CSV is empty.", status_code=400)

        # Header parsing
        headers = [h.strip().lower() for h in lines[0].split(",")]
        required = ["full_name", "email", "role"]
        for r in required:
            if r not in headers:
                raise AppError(
                    code="invalid_csv_headers",
                    message=f"Missing required CSV column '{r}'. Required: full_name, email, role, [batch, department]",
                    status_code=422,
                )

        idx_map = {h: i for i, h in enumerate(headers)}
        total = 0
        inserted = 0
        duplicates = 0
        errors: list[str] = []

        # Load existing emails for institution
        existing_res = await db.execute(
            select(ApprovedMember.email).where(ApprovedMember.institution_id == institution_id)
        )
        existing_emails = set(existing_res.scalars().all())

        for line_num, line in enumerate(lines[1:], start=2):
            total += 1
            parts = [p.strip().strip('"').strip("'") for p in line.split(",")]
            if len(parts) < len(required):
                errors.append(f"Line {line_num}: Insufficient columns.")
                continue

            name = parts[idx_map["full_name"]]
            email = parts[idx_map["email"]].lower()
            role = parts[idx_map["role"]].lower()
            batch = parts[idx_map["batch"]] if "batch" in idx_map and idx_map["batch"] < len(parts) else None
            dept = parts[idx_map["department"]] if "department" in idx_map and idx_map["department"] < len(parts) else None

            if not email or "@" not in email:
                errors.append(f"Line {line_num}: Invalid email '{email}'.")
                continue

            if role not in ["student", "alumnus", "faculty"]:
                errors.append(f"Line {line_num}: Invalid role '{role}'. Must be student, alumnus, or faculty.")
                continue

            if email in existing_emails:
                duplicates += 1
                continue

            member = ApprovedMember(
                institution_id=institution_id,
                email=email,
                full_name=name,
                role=role,
                batch=batch,
                department=dept,
                created_at=datetime.now(UTC),
            )
            db.add(member)
            existing_emails.add(email)
            inserted += 1

        # Audit log
        audit = AuditLog(
            id=uuid4(),
            actor_id=admin.id,
            actor_email=admin.email,
            action="approved_members.upload",
            target_type="approved_members",
            target_id=str(institution_id),
            institution_id=institution_id,
            details={"total_rows": total, "inserted": inserted, "duplicates_skipped": duplicates},
            created_at=datetime.now(UTC),
        )
        db.add(audit)

        await db.commit()
        return ApprovedMembersUploadResponse(
            total_rows=total,
            inserted=inserted,
            duplicates_skipped=duplicates,
            errors=errors[:10],
        )

    @staticmethod
    async def get_audit_log(
        user: User,
        action: str | None,
        actor_id: UUID | None,
        target_id: str | None,
        cursor: str | None,
        limit: int,
        db: AsyncSession,
    ) -> dict[str, Any]:
        stmt = select(AuditLog).order_by(AuditLog.created_at.desc()).limit(limit)

        if action:
            stmt = stmt.where(AuditLog.action == action)
        if actor_id:
            stmt = stmt.where(AuditLog.actor_id == actor_id)
        if target_id:
            stmt = stmt.where(AuditLog.target_id == target_id)

        # Scoping for institution_admin
        if (
            "institution_admin" in (user.roles or [])
            and "platform_admin" not in (user.roles or [])
            and "moderator" not in (user.roles or [])
            and user.institution_id
        ):
            stmt = stmt.where(AuditLog.institution_id == user.institution_id)

        res = await db.execute(stmt)
        logs = res.scalars().all()

        items = [
            {
                "id": str(log.id),
                "actor_id": str(log.actor_id),
                "actor_email": log.actor_email,
                "action": log.action,
                "target_type": log.target_type,
                "target_id": log.target_id,
                "institution_id": log.institution_id,
                "details": log.details,
                "created_at": _ensure_utc(log.created_at),
            }
            for log in logs
        ]

        next_cursor = str(items[-1]["created_at"].timestamp()) if len(items) == limit else None
        return {"items": items, "next_cursor": next_cursor}
