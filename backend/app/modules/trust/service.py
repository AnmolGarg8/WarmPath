from sqlalchemy.ext.asyncio import AsyncSession


class TrustService:
    def __init__(self, session: AsyncSession):
        self.session = session
