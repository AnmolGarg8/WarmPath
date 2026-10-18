import uuid
from datetime import datetime, timedelta, timezone
from unittest.mock import AsyncMock, MagicMock
import pytest
from app.modules.ratings.service import RatingsService

def test_smoothed_average_formula():
    # Prior mean = 4.0, prior weight = 5.0
    # No ratings: (4.0 * 5) / 5 = 4.0
    avg, count = RatingsService.calculate_smoothed_average([])
    assert avg == 4.0
    assert count == 0

    # 5 ratings of 5-star (weight 1.0):
    # (4.0 * 5 + 25) / (5 + 5) = 45 / 10 = 4.5
    ratings = [(5, 1.0)] * 5
    avg, count = RatingsService.calculate_smoothed_average(ratings)
    assert avg == 4.5
    assert count == 5

    # 5 ratings of 1-star (weight 1.0):
    # (4.0 * 5 + 5) / (5 + 5) = 25 / 10 = 2.5
    low_ratings = [(1, 1.0)] * 5
    avg, count = RatingsService.calculate_smoothed_average(low_ratings)
    assert avg == 2.5

def test_band_thresholds_and_5_session_rule():
    # Less than 5 rated sessions cannot change from Rising
    band = RatingsService.evaluate_band(
        current_band="Rising",
        smoothed_avg=4.9,
        rated_count=4,
        completion_rate=1.0
    )
    assert band == "Rising"

    # Exactly 5 rated sessions with smoothed >= 4.2 upgrades to Trusted
    band_trusted = RatingsService.evaluate_band(
        current_band="Rising",
        smoothed_avg=4.25,
        rated_count=5,
        completion_rate=1.0
    )
    assert band_trusted == "Trusted"

    # 10 rated sessions with smoothed >= 4.6 and completion rate >= 0.90 upgrades to Top Rated
    band_top = RatingsService.evaluate_band(
        current_band="Trusted",
        smoothed_avg=4.65,
        rated_count=10,
        completion_rate=0.95
    )
    assert band_top == "Top Rated"

def test_band_hysteresis():
    # Top Rated does not drop to Trusted immediately on minor dip (buffer 0.05)
    # Threshold is 4.60, so 4.58 with buffer stays Top Rated
    band = RatingsService.evaluate_band(
        current_band="Top Rated",
        smoothed_avg=4.58,
        rated_count=12,
        completion_rate=0.95
    )
    assert band == "Top Rated"

    # Serious drop to 4.3 drops to Trusted
    band_demote = RatingsService.evaluate_band(
        current_band="Top Rated",
        smoothed_avg=4.30,
        rated_count=12,
        completion_rate=0.95
    )
    assert band_demote == "Trusted"

@pytest.mark.asyncio
async def test_student_rating_fails_when_caller_not_student():
    from app.modules.ratings.router import post_session_rating
    from app.modules.ratings.schemas import StudentRatingCreate
    from app.modules.sessions.models import CallSession
    from app.core.errors import AppError

    mock_db = AsyncMock()
    session_id = uuid.uuid4()
    student_id = uuid.uuid4()
    giver_id = uuid.uuid4()
    other_user_id = uuid.uuid4()

    call = CallSession(
        id=session_id,
        request_id=uuid.uuid4(),
        student_id=student_id,
        giver_id=giver_id,
        scheduled_at=datetime.now(timezone.utc),
        duration_minutes=20,
        room_url="https://meet.jit.si/test",
        status="completed"
    )
    mock_execute = MagicMock()
    mock_execute.scalar_one_or_none.return_value = call
    mock_db.execute = AsyncMock(return_value=mock_execute)

    data = StudentRatingCreate(stars=5, reason="Great")
    with pytest.raises(AppError) as exc_info:
        await post_session_rating(id=str(session_id), data=data, db=mock_db, user_id=str(other_user_id))
    assert exc_info.value.code == "unauthorized"

@pytest.mark.asyncio
async def test_student_rating_fails_when_session_not_completed():
    from app.modules.ratings.router import post_session_rating
    from app.modules.ratings.schemas import StudentRatingCreate
    from app.modules.sessions.models import CallSession
    from app.core.errors import AppError

    mock_db = AsyncMock()
    session_id = uuid.uuid4()
    student_id = uuid.uuid4()
    giver_id = uuid.uuid4()

    call = CallSession(
        id=session_id,
        request_id=uuid.uuid4(),
        student_id=student_id,
        giver_id=giver_id,
        scheduled_at=datetime.now(timezone.utc),
        duration_minutes=20,
        room_url="https://meet.jit.si/test",
        status="scheduled"
    )
    mock_execute = MagicMock()
    mock_execute.scalar_one_or_none.return_value = call
    mock_db.execute = AsyncMock(return_value=mock_execute)

    data = StudentRatingCreate(stars=5)
    with pytest.raises(AppError) as exc_info:
        await post_session_rating(id=str(session_id), data=data, db=mock_db, user_id=str(student_id))
    assert exc_info.value.code == "session_not_completed"

@pytest.mark.asyncio
async def test_student_rating_fails_after_14_days():
    from app.modules.ratings.router import post_session_rating
    from app.modules.ratings.schemas import StudentRatingCreate
    from app.modules.sessions.models import CallSession
    from app.core.errors import AppError

    mock_db = AsyncMock()
    session_id = uuid.uuid4()
    student_id = uuid.uuid4()
    giver_id = uuid.uuid4()

    call = CallSession(
        id=session_id,
        request_id=uuid.uuid4(),
        student_id=student_id,
        giver_id=giver_id,
        scheduled_at=datetime.now(timezone.utc) - timedelta(days=15),
        student_left_at=datetime.now(timezone.utc) - timedelta(days=15),
        duration_minutes=20,
        room_url="https://meet.jit.si/test",
        status="completed"
    )
    mock_execute = MagicMock()
    mock_execute.scalar_one_or_none.return_value = call
    mock_db.execute = AsyncMock(return_value=mock_execute)

    data = StudentRatingCreate(stars=5)
    with pytest.raises(AppError) as exc_info:
        await post_session_rating(id=str(session_id), data=data, db=mock_db, user_id=str(student_id))
    assert exc_info.value.code == "rating_window_expired"
