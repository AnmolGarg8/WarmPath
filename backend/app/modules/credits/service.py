from sqlalchemy.ext.asyncio import AsyncSession


class CreditsService:
    def __init__(self, session: AsyncSession):
        self.session = session
