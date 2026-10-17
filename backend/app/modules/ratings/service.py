from sqlalchemy.ext.asyncio import AsyncSession
from app.core.config import settings


class RatingsService:
    def __init__(self, session: AsyncSession):
        self.session = session

    @staticmethod
    def calculate_smoothed_average(ratings: list[int], prior_mean: float = 4.0, prior_weight: int = 5) -> float:
        n = len(ratings)
        return (prior_mean * prior_weight + sum(ratings)) / (prior_weight + n)

    @staticmethod
    def determine_band(smoothed_avg: float, rated_count: int, completion_rate: float) -> str:
        if rated_count < 5:
            return "Rising"
        if smoothed_avg >= settings.TOP_RATED_MIN_AVG and rated_count >= settings.TOP_RATED_MIN_SESSIONS and completion_rate >= settings.TOP_RATED_MIN_COMPLETION:
            return "Top Rated"
        if smoothed_avg >= settings.TRUSTED_MIN_AVG:
            return "Trusted"
        return "Rising"
