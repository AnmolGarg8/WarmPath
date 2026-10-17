from sqlalchemy.ext.asyncio import AsyncSession


class ResumeService:
    def __init__(self, session: AsyncSession):
        self.session = session
