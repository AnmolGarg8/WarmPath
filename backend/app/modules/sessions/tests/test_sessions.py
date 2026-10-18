import uuid
from datetime import datetime, timedelta, timezone
import pytest
from unittest.mock import AsyncMock, patch, MagicMock

from app.modules.sessions.service import SessionsService, mask_contact_info
from app.modules.sessions.models import MentorshipRequest, CallSession
from app.core.errors import AppError
from app.core.ports import ports

def test_mask_contact_info():
    text = "Hey reach me at test.user@example.com or call +1 555-123-4567!"
    masked = mask_contact_info(text)
    assert "test.user@example.com" not in masked
    assert "[email protected]" in masked
    assert "[phone number redacted]" in masked

@pytest.mark.asyncio
async def test_create_request_fails_closed_when_trust_denies():
    mock_session = AsyncMock()
    student_id = uuid.uuid4()
    giver_id = uuid.uuid4()

    with patch.object(ports.trust, "can", AsyncMock(return_value={"allowed": False, "reason": "Unverified"})):
        with pytest.raises(AppError) as exc_info:
            await SessionsService.create_request(
                session=mock_session,
                student_id=student_id,
                giver_id=giver_id,
                kind="instant",
                intent_text="Want resume review",
                slot_start=None
            )
        assert exc_info.value.code == "trust_denied"

@pytest.mark.asyncio
async def test_create_request_fails_closed_when_blocked():
    mock_session = AsyncMock()
    student_id = uuid.uuid4()
    giver_id = uuid.uuid4()

    with patch.object(ports.trust, "can", AsyncMock(return_value={"allowed": True})), \
         patch.object(ports.trust, "is_blocked", AsyncMock(return_value=True)):
        with pytest.raises(AppError) as exc_info:
            await SessionsService.create_request(
                session=mock_session,
                student_id=student_id,
                giver_id=giver_id,
                kind="instant",
                intent_text="Let's connect",
                slot_start=None
            )
        assert exc_info.value.code == "communication_blocked"

@pytest.mark.asyncio
async def test_create_request_fails_when_giver_has_no_capacity():
    mock_session = AsyncMock()
    student_id = uuid.uuid4()
    giver_id = uuid.uuid4()

    with patch.object(ports.trust, "can", AsyncMock(return_value={"allowed": True})), \
         patch.object(ports.trust, "is_blocked", AsyncMock(return_value=False)), \
         patch.object(ports.presence, "status", AsyncMock(return_value={str(giver_id): {"capacity_left": 0}})):
        with pytest.raises(AppError) as exc_info:
            await SessionsService.create_request(
                session=mock_session,
                student_id=student_id,
                giver_id=giver_id,
                kind="instant",
                intent_text="Let's connect",
                slot_start=None
            )
        assert exc_info.value.code == "giver_at_capacity"

@pytest.mark.asyncio
async def test_create_request_fails_when_credits_denies():
    mock_session = AsyncMock()
    student_id = uuid.uuid4()
    giver_id = uuid.uuid4()

    with patch.object(ports.trust, "can", AsyncMock(return_value={"allowed": True})), \
         patch.object(ports.trust, "is_blocked", AsyncMock(return_value=False)), \
         patch.object(ports.presence, "status", AsyncMock(return_value={str(giver_id): {"capacity_left": 3, "online": True}})), \
         patch.object(ports.credits, "can_access", AsyncMock(return_value={"allowed": False, "reason": "Upgrade needed"})):
        with pytest.raises(AppError) as exc_info:
            await SessionsService.create_request(
                session=mock_session,
                student_id=student_id,
                giver_id=giver_id,
                kind="instant",
                intent_text="Need mentorship",
                slot_start=None
            )
        assert exc_info.value.code == "plan_access_denied"

@pytest.mark.asyncio
async def test_create_request_fails_when_safety_blocks_intent():
    mock_session = AsyncMock()
    student_id = uuid.uuid4()
    giver_id = uuid.uuid4()

    with patch.object(ports.trust, "can", AsyncMock(return_value={"allowed": True})), \
         patch.object(ports.trust, "is_blocked", AsyncMock(return_value=False)), \
         patch.object(ports.presence, "status", AsyncMock(return_value={str(giver_id): {"capacity_left": 3, "online": True}})), \
         patch.object(ports.credits, "can_access", AsyncMock(return_value={"allowed": True, "plan": "Campus", "cost": 0})), \
         patch.object(ports.safety, "scan_text", AsyncMock(return_value={"action": "block"})):
        with pytest.raises(AppError) as exc_info:
            await SessionsService.create_request(
                session=mock_session,
                student_id=student_id,
                giver_id=giver_id,
                kind="instant",
                intent_text="Inappropriate intent text",
                slot_start=None
            )
        assert exc_info.value.code == "intent_blocked"

def test_giver_earnings_text():
    assert SessionsService.get_giver_earnings_text(True) == "You earn Rs 175 if completed"
    assert SessionsService.get_giver_earnings_text(False) == "Free campus session, you earn 1 affinity credit"

@pytest.mark.asyncio
async def test_join_session_enforces_join_window_before():
    mock_session = AsyncMock()
    session_id = uuid.uuid4()
    student_id = uuid.uuid4()
    giver_id = uuid.uuid4()

    # Session scheduled 1 hour in future (outside 10 min window)
    now = datetime.now(timezone.utc)
    future_time = now + timedelta(hours=1)
    call = CallSession(
        id=session_id,
        request_id=uuid.uuid4(),
        student_id=student_id,
        giver_id=giver_id,
        scheduled_at=future_time,
        duration_minutes=20,
        room_url="https://meet.jit.si/test",
        status="scheduled"
    )

    mock_execute = MagicMock()
    mock_execute.scalar_one_or_none.return_value = call
    mock_session.execute = AsyncMock(return_value=mock_execute)

    with pytest.raises(AppError) as exc_info:
        await SessionsService.join_session(mock_session, session_id, student_id)
    assert exc_info.value.code == "session_not_open"
    assert "Opens 10 minutes before the start" in exc_info.value.message or "Session opens 10 minutes" in exc_info.value.message

@pytest.mark.asyncio
async def test_join_session_enforces_join_window_ended():
    mock_session = AsyncMock()
    session_id = uuid.uuid4()
    student_id = uuid.uuid4()
    giver_id = uuid.uuid4()

    # Session scheduled 2 hours in past (already ended)
    now = datetime.now(timezone.utc)
    past_time = now - timedelta(hours=2)
    call = CallSession(
        id=session_id,
        request_id=uuid.uuid4(),
        student_id=student_id,
        giver_id=giver_id,
        scheduled_at=past_time,
        duration_minutes=20,
        room_url="https://meet.jit.si/test",
        status="scheduled"
    )

    mock_execute = MagicMock()
    mock_execute.scalar_one_or_none.return_value = call
    mock_session.execute = AsyncMock(return_value=mock_execute)

    with pytest.raises(AppError) as exc_info:
        await SessionsService.join_session(mock_session, session_id, student_id)
    assert exc_info.value.code == "session_not_open"
    assert "already ended" in exc_info.value.message

@pytest.mark.asyncio
async def test_join_session_allows_join_within_window():
    mock_session = AsyncMock()
    session_id = uuid.uuid4()
    student_id = uuid.uuid4()
    giver_id = uuid.uuid4()

    # Session scheduled 5 mins from now (within 10 min window)
    now = datetime.now(timezone.utc)
    imminent_time = now + timedelta(minutes=5)
    call = CallSession(
        id=session_id,
        request_id=uuid.uuid4(),
        student_id=student_id,
        giver_id=giver_id,
        scheduled_at=imminent_time,
        duration_minutes=20,
        room_url="https://meet.jit.si/test",
        status="scheduled"
    )

    mock_execute = MagicMock()
    mock_execute.scalar_one_or_none.return_value = call
    mock_session.execute = AsyncMock(return_value=mock_execute)

    result = await SessionsService.join_session(mock_session, session_id, student_id)
    assert result.status == "in_progress"
    assert result.student_joined_at is not None
