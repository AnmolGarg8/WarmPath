from sqlalchemy.ext.asyncio import AsyncSession


class InstitutionService:
    def __init__(self, session: AsyncSession):
        self.session = session
