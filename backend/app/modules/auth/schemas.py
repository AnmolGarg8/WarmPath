"""
backend/app/modules/auth/schemas.py - Request and response schemas for authentication and verification.
"""

import json
from datetime import datetime
from typing import Any
from uuid import UUID

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator


class RequestOtpRequest(BaseModel):
    email: EmailStr


class RequestOtpResponse(BaseModel):
    message: str
    email: str


class VerifyOtpRequest(BaseModel):
    email: EmailStr
    code: str = Field(..., min_length=6, max_length=6, pattern="^[0-9]{6}$")


class InstitutionSchema(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    short_name: str | None = None
    city: str | None = None
    email_domains: Any

    @field_validator("email_domains", mode="before")
    def parse_domains(cls, v):
        if isinstance(v, str):
            try:
                return json.loads(v)
            except Exception:
                return [v]
        return v or []


class UserSchema(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    email: str
    full_name: str
    display_name: str | None = None
    headline: str | None = None
    avatar_url: str | None = None
    institution_id: int | None = None
    institution: InstitutionSchema | None = None
    roles: Any
    verification_level: str
    badges: Any
    trust_level: str
    status: str
    created_at: datetime
    last_seen_at: datetime | None = None

    @field_validator("roles", "badges", mode="before")
    def parse_list_fields(cls, v):
        if isinstance(v, str):
            try:
                return json.loads(v)
            except Exception:
                return [v]
        return v or []


class AuthResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user: UserSchema
    is_new: bool


class RefreshTokenRequest(BaseModel):
    refresh_token: str


class RefreshTokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class LogoutRequest(BaseModel):
    refresh_token: str | None = None


class UpdateMeRequest(BaseModel):
    display_name: str | None = None
    headline: str | None = None
    avatar_url: str | None = None


class VerificationSubmitRequest(BaseModel):
    kind: str = Field(..., pattern="^(alumnus|employer|expert|faculty)$")
    evidence_text: str = Field(..., min_length=10)
    evidence_urls: list[str] | None = None
    company_name: str | None = None
    company_registration: str | None = None


class VerificationRequestSchema(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    user_id: UUID
    kind: str
    evidence_text: str
    evidence_urls: Any | None = None
    company_name: str | None = None
    company_registration: str | None = None
    status: str
    decision_reason: str | None = None
    created_at: datetime
    updated_at: datetime

    @field_validator("evidence_urls", mode="before")
    def parse_urls(cls, v):
        if isinstance(v, str):
            try:
                return json.loads(v)
            except Exception:
                return [v]
        return v or []


class VerificationStatusResponse(BaseModel):
    verification_level: str
    badges: list[str]
    trust_level: str
    pending_requests: list[VerificationRequestSchema]


class DataExportResponse(BaseModel):
    user: UserSchema
    verification_requests: list[VerificationRequestSchema]
    approved_member_record: dict[str, Any] | None = None
    modules_data: dict[str, Any] = Field(default_factory=dict)
    exported_at: datetime
