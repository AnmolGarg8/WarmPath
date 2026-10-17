import uuid
from datetime import datetime
from pydantic import BaseModel, EmailStr


class RequestOTPRequest(BaseModel):
    email: EmailStr


class VerifyOTPRequest(BaseModel):
    email: EmailStr
    code: str


class RefreshTokenRequest(BaseModel):
    refresh_token: str


class UpdateProfileRequest(BaseModel):
    full_name: str | None = None


class VerificationSubmitRequest(BaseModel):
    document_type: str  # id_card | marksheet | admission_letter
    document_url: str


class UserResponse(BaseModel):
    id: uuid.UUID
    email: EmailStr
    full_name: str
    institution_id: uuid.UUID | None = None
    roles: list[str]
    created_at: datetime
