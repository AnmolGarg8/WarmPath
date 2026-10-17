from sqlalchemy.ext.asyncio import AsyncSession


class MatchingService:
    def __init__(self, session: AsyncSession):
        self.session = session
