import uuid
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
