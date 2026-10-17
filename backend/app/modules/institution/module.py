"""
Module descriptor for 'institution'.
Owner: M4
Wires outbox event subscriptions into reporting projection tables.
"""

from app.core.db import async_session_maker
from app.core.events import (
    CreditsReleasedPayload,
    DisputeOpenedPayload,
    DisputeResolvedPayload,
    EventBus,
    GiverProfileUpdatedPayload,
    RatingSubmittedPayload,
    ReportFiledPayload,
    RequestAcceptedPayload,
    RequestCreatedPayload,
    RequestDeclinedPayload,
    SessionBookedPayload,
    SessionCompletedPayload,
    SessionNoShowPayload,
    UserVerifiedPayload,
)
from app.core.ports import PortRegistry
from app.modules.institution.router import router as ROUTER
from app.modules.institution.service import InstitutionService


async def on_user_verified(payload: UserVerifiedPayload) -> None:
    async with async_session_maker() as session, session.begin():
        await InstitutionService.project_user_verified(
            session=session,
            user_id=payload.user_id,
            institution_id=payload.institution_id,
            role=payload.role,
        )


async def on_giver_profile_updated(payload: GiverProfileUpdatedPayload) -> None:
    async with async_session_maker() as session, session.begin():
        await InstitutionService.project_giver_profile_updated(
            session=session,
            giver_id=payload.giver_id,
            topics=payload.topics,
        )


async def on_request_created(payload: RequestCreatedPayload) -> None:
    async with async_session_maker() as session, session.begin():
        await InstitutionService.project_request_created(
            session=session,
            request_id=payload.request_id,
            student_id=payload.student_id,
            giver_id=payload.giver_id,
            is_cross_college=payload.is_cross_college,
        )


async def on_request_accepted(payload: RequestAcceptedPayload) -> None:
    async with async_session_maker() as session, session.begin():
        await InstitutionService.project_request_accepted(
            session=session,
            request_id=payload.request_id,
        )


async def on_request_declined(payload: RequestDeclinedPayload) -> None:
    async with async_session_maker() as session, session.begin():
        await InstitutionService.project_request_declined(
            session=session,
            request_id=payload.request_id,
        )


async def on_session_booked(payload: SessionBookedPayload) -> None:
    async with async_session_maker() as session, session.begin():
        await InstitutionService.project_session_booked(
            session=session,
            session_id=payload.session_id,
            request_id=payload.request_id,
            student_id=payload.student_id,
            giver_id=payload.giver_id,
        )


async def on_session_completed(payload: SessionCompletedPayload) -> None:
    async with async_session_maker() as session, session.begin():
        await InstitutionService.project_session_completed(
            session=session,
            session_id=payload.session_id,
            duration_minutes=payload.duration_minutes,
        )


async def on_session_no_show(payload: SessionNoShowPayload) -> None:
    async with async_session_maker() as session, session.begin():
        await InstitutionService.project_session_no_show(
            session=session,
            session_id=payload.session_id,
            no_show_party=payload.no_show_party,
        )


async def on_rating_submitted(payload: RatingSubmittedPayload) -> None:
    async with async_session_maker() as session, session.begin():
        await InstitutionService.project_rating_submitted(
            session=session,
            session_id=payload.session_id,
            rating=payload.rating,
        )


async def on_report_filed(payload: ReportFiledPayload) -> None:
    async with async_session_maker() as session, session.begin():
        await InstitutionService.project_report_filed(
            session=session,
            report_id=payload.report_id,
            reporter_id=payload.reporter_id,
            reported_user_id=payload.reported_user_id,
            reason=payload.reason,
        )


async def on_dispute_opened(payload: DisputeOpenedPayload) -> None:
    async with async_session_maker() as session, session.begin():
        await InstitutionService.project_dispute_opened(
            session=session,
            dispute_id=payload.dispute_id,
            session_id=payload.session_id,
            reason=payload.reason,
        )


async def on_dispute_resolved(payload: DisputeResolvedPayload) -> None:
    async with async_session_maker() as session, session.begin():
        await InstitutionService.project_dispute_resolved(
            session=session,
            dispute_id=payload.dispute_id,
            outcome=payload.outcome,
        )


def register_events(bus: EventBus) -> None:
    """Register outbox event handlers for institution read-model projections."""
    bus.subscribe("user.verified", on_user_verified)
    bus.subscribe("giver.profile_updated", on_giver_profile_updated)
    bus.subscribe("request.created", on_request_created)
    bus.subscribe("request.accepted", on_request_accepted)
    bus.subscribe("request.declined", on_request_declined)
    bus.subscribe("session.booked", on_session_booked)
    bus.subscribe("session.completed", on_session_completed)
    bus.subscribe("session.no_show", on_session_no_show)
    bus.subscribe("rating.submitted", on_rating_submitted)
    bus.subscribe("report.filed", on_report_filed)
    bus.subscribe("dispute.opened", on_dispute_opened)
    bus.subscribe("dispute.resolved", on_dispute_resolved)


def register_ports(registry: PortRegistry) -> None:
    """Register synchronous ports if any."""
    pass
