from sqlalchemy.ext.asyncio import AsyncSession
from app.core.errors import ModuleNotImplemented


class AuthService:
    def __init__(self, session: AsyncSession):
        self.session = session
