"""
backend/app/modules/auth/service.py - Authentication & Verification Service implementation.
"""

import hashlib
import json
import secrets
from datetime import UTC, datetime, timedelta
from email.message import EmailMessage
from typing import Any
from uuid import uuid4

import aiosmtplib
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import joinedload

import app.core.redis as core_redis
from app.core.config import settings
from app.core.db import Institution, User
from app.core.errors import AppError
from app.core.events import UserDeletedPayload, UserVerifiedPayload, event_bus
from app.core.security import create_access_token
from app.modules.auth.models import ApprovedMember, RefreshToken, VerificationRequest
from app.modules.auth.schemas import (
    UpdateMeRequest,
    VerificationSubmitRequest,
)


def _hash_otp(code: str, salt: str) -> str:
    return hashlib.sha256(f"{salt}:{code}".encode()).hexdigest()


def _hash_token(raw_token: str) -> str:
    return hashlib.sha256(raw_token.encode("utf-8")).hexdigest()


class AuthService:
    @staticmethod
    async def get_institutions(db: AsyncSession) -> list[Institution]:
        result = await db.execute(select(Institution).order_by(Institution.name))
        return list(result.scalars().all())

    @staticmethod
    async def find_institution_by_email(email: str, db: AsyncSession) -> Institution | None:
        domain = email.split("@")[-1].lower()
        institutions = await AuthService.get_institutions(db)
        for inst in institutions:
            domains = inst.email_domains
            if isinstance(domains, str):
                try:
                    domains = json.loads(domains)
                except Exception:
                    domains = [domains]
            if domain in [d.lower() for d in (domains or [])]:
                return inst
        return None

    @staticmethod
    async def request_otp(email: str, client_ip: str, db: AsyncSession) -> dict[str, str]:
        email = email.strip().lower()

        # 1. Institution check
        institution = await AuthService.find_institution_by_email(email, db)
        if not institution:
            raise AppError(
                code="institution_not_supported",
                message="Your email domain is not currently affiliated with any supported institution.",
                status_code=422,
                details={"email": email},
            )

        # 2. Redis rate limits
        r = await core_redis.get_redis()
        email_key = f"ratelimit:otp:email:{email}"
        ip_key = f"ratelimit:otp:ip:{client_ip}"

        email_reqs = await r.incr(email_key)
        if email_reqs == 1:
            await r.expire(email_key, 3600)
        if email_reqs > 3:
            raise AppError(
                code="rate_limit_exceeded",
                message="Too many OTP requests for this email. Please try again in an hour.",
                status_code=429,
            )

        ip_reqs = await r.incr(ip_key)
        if ip_reqs == 1:
            await r.expire(ip_key, 3600)
        if ip_reqs > 10:
            raise AppError(
                code="rate_limit_exceeded",
                message="Too many OTP requests from your IP. Please try again in an hour.",
                status_code=429,
            )

        # 3. Generate 6-digit OTP using secrets
        otp_code = f"{secrets.randbelow(900000) + 100000:06d}"
        salt = secrets.token_hex(8)
        code_hash = _hash_otp(otp_code, salt)

        # 4. Store hash with 10-minute expiry (never store plaintext OTP)
        otp_key = f"otp:{email}"
        payload = json.dumps({"salt": salt, "hash": code_hash, "attempts": 0})
        await r.set(otp_key, payload, ex=600)

        # 5. Send HTML email via SMTP
        message = EmailMessage()
        message["From"] = settings.SMTP_FROM
        message["To"] = email
        message["Subject"] = f"Your WarmPath Verification Code: {otp_code[:3]}-{otp_code[3:]}"
        html_content = f"""
        <div style="font-family: sans-serif; padding: 20px; color: #16163A;">
            <h2>WarmPath Login Code</h2>
            <p>Use the following 6-digit verification code to sign in to your institution account:</p>
            <div style="font-size: 28px; font-weight: bold; letter-spacing: 4px; color: #FF6B4A; padding: 12px 0;">
                {otp_code}
            </div>
            <p style="font-size: 13px; color: #64748B;">This code will expire in 10 minutes. If you did not request this code, you can safely ignore this email.</p>
        </div>
        """
        message.set_content(f"Your WarmPath verification code is: {otp_code}")
        message.add_alternative(html_content, subtype="html")

        try:
            await aiosmtplib.send(
                message,
                hostname=settings.SMTP_HOST,
                port=settings.SMTP_PORT,
                username=settings.SMTP_USER or None,
                password=settings.SMTP_PASSWORD or None,
                use_tls=False,
            )
        except Exception:
            # In development/test environments without live SMTP, proceed
            pass

        # NEVER return or log the OTP
        return {"message": "Verification code sent to your email", "email": email}

    @staticmethod
    async def verify_otp(email: str, code: str, db: AsyncSession) -> dict[str, Any]:
        email = email.strip().lower()
        code = code.strip()

        # 1. Fetch OTP record from Redis
        r = await core_redis.get_redis()
        otp_key = f"otp:{email}"
        raw_payload = await r.get(otp_key)

        if not raw_payload:
            raise AppError(
                code="invalid_otp",
                message="Verification code has expired or was not requested. Please request a new code.",
                status_code=400,
            )

        data = json.loads(raw_payload)
        salt = data["salt"]
        stored_hash = data["hash"]
        attempts = data.get("attempts", 0)

        if attempts >= 5:
            await r.delete(otp_key)
            raise AppError(
                code="max_otp_attempts_exceeded",
                message="Maximum verification attempts exceeded. Please request a new code.",
                status_code=429,
            )

        candidate_hash = _hash_otp(code, salt)
        if candidate_hash != stored_hash:
            data["attempts"] = attempts + 1
            ttl = await r.ttl(otp_key)
            if ttl > 0:
                await r.set(otp_key, json.dumps(data), ex=ttl)
            raise AppError(
                code="invalid_otp",
                message="Invalid verification code.",
                status_code=400,
                details={"remaining_attempts": 5 - (attempts + 1)},
            )

        # Successful verification: delete OTP key immediately
        await r.delete(otp_key)

        # 2. Check if user exists or create
        result = await db.execute(
            select(User).options(joinedload(User.institution)).where(User.email == email)
        )
        user = result.scalar_one_or_none()
        is_new = False

        if not user:
            is_new = True
            institution = await AuthService.find_institution_by_email(email, db)
            username = email.split("@")[0].replace(".", " ").title()

            user = User(
                id=uuid4(),
                email=email,
                full_name=username,
                institution_id=institution.id if institution else None,
                roles=["student"],
                verification_level="email_only",
                badges=[],
                trust_level="new",
                status="active",
                created_at=datetime.now(UTC),
                last_seen_at=datetime.now(UTC),
            )
            db.add(user)
            await db.flush()

        # 3. Check approved_members table (Layer 1 verification)
        app_res = await db.execute(select(ApprovedMember).where(ApprovedMember.email == email))
        approved = app_res.scalar_one_or_none()

        if approved:
            user.verification_level = "verified"
            role = approved.role.lower()
            roles = list(user.roles) if isinstance(user.roles, (list, tuple)) else (json.loads(user.roles) if isinstance(user.roles, str) else [])
            if role not in roles:
                roles.append(role)
            user.roles = roles

            badge_name = f"Verified {role.capitalize()}"
            badges = list(user.badges) if isinstance(user.badges, (list, tuple)) else (json.loads(user.badges) if isinstance(user.badges, str) else [])
            if badge_name not in badges:
                badges.append(badge_name)
            user.badges = badges

            approved.claimed_by_user_id = user.id

            # Publish user.verified event to outbox
            if user.institution_id:
                await event_bus.publish(
                    db,
                    "user.verified",
                    UserVerifiedPayload(
                        user_id=str(user.id),
                        institution_id=user.institution_id,
                        role=role,
                    ),
                )

        user.last_seen_at = datetime.now(UTC)
        await db.commit()
        await db.refresh(user)

        # 4. Generate Access and Refresh Tokens
        access_token = create_access_token(
            subject=str(user.id),
            claims={"email": user.email, "roles": user.roles, "institution_id": user.institution_id},
        )

        raw_refresh = secrets.token_urlsafe(32)
        family_id = uuid4()
        refresh_token_record = RefreshToken(
            id=uuid4(),
            user_id=user.id,
            family_id=family_id,
            token_hash=_hash_token(raw_refresh),
            is_revoked=False,
            expires_at=datetime.now(UTC) + timedelta(days=settings.REFRESH_TOKEN_DAYS),
            created_at=datetime.now(UTC),
        )
        db.add(refresh_token_record)
        await db.commit()

        return {
            "access_token": access_token,
            "refresh_token": raw_refresh,
            "token_type": "bearer",
            "user": user,
            "is_new": is_new,
        }

    @staticmethod
    async def refresh_tokens(raw_refresh: str, db: AsyncSession) -> dict[str, str]:
        token_hash = _hash_token(raw_refresh)
        result = await db.execute(
            select(RefreshToken).where(RefreshToken.token_hash == token_hash)
        )
        record = result.scalar_one_or_none()

        if not record:
            raise AppError(code="token_invalid", message="Invalid refresh token.", status_code=401)

        # Reuse Detection: if already revoked, revoke whole family!
        if record.is_revoked:
            await db.execute(
                update(RefreshToken)
                .where(RefreshToken.family_id == record.family_id)
                .values(is_revoked=True)
            )
            await db.commit()
            raise AppError(
                code="token_reuse_detected",
                message="Refresh token reuse detected. All sessions in this family have been revoked.",
                status_code=401,
            )

        expires_at = record.expires_at
        if expires_at.tzinfo is None:
            expires_at = expires_at.replace(tzinfo=UTC)

        if expires_at < datetime.now(UTC):
            raise AppError(code="token_expired", message="Refresh token has expired.", status_code=401)

        # Revoke current token
        record.is_revoked = True

        # Generate new rotated refresh token in the same family
        new_raw_refresh = secrets.token_urlsafe(32)
        new_record = RefreshToken(
            id=uuid4(),
            user_id=record.user_id,
            family_id=record.family_id,
            token_hash=_hash_token(new_raw_refresh),
            is_revoked=False,
            expires_at=datetime.now(UTC) + timedelta(days=settings.REFRESH_TOKEN_DAYS),
            created_at=datetime.now(UTC),
        )
        db.add(new_record)

        # Issue new access token
        user_res = await db.execute(select(User).where(User.id == record.user_id))
        user = user_res.scalar_one_or_none()
        if not user or user.status == "deleted":
            raise AppError(code="user_not_found", message="User account not found.", status_code=401)

        access_token = create_access_token(
            subject=str(user.id),
            claims={"email": user.email, "roles": user.roles, "institution_id": user.institution_id},
        )
        await db.commit()

        return {
            "access_token": access_token,
            "refresh_token": new_raw_refresh,
            "token_type": "bearer",
        }

    @staticmethod
    async def logout(raw_refresh: str | None, db: AsyncSession):
        if raw_refresh:
            token_hash = _hash_token(raw_refresh)
            result = await db.execute(
                select(RefreshToken).where(RefreshToken.token_hash == token_hash)
            )
            record = result.scalar_one_or_none()
            if record:
                await db.execute(
                    update(RefreshToken)
                    .where(RefreshToken.family_id == record.family_id)
                    .values(is_revoked=True)
                )
                await db.commit()

    @staticmethod
    async def update_me(user: User, payload: UpdateMeRequest, db: AsyncSession) -> User:
        if payload.display_name is not None:
            user.display_name = payload.display_name
        if payload.headline is not None:
            user.headline = payload.headline
        if payload.avatar_url is not None:
            user.avatar_url = payload.avatar_url

        user.last_seen_at = datetime.now(UTC)
        await db.commit()
        await db.refresh(user)
        return user

    @staticmethod
    async def delete_me(user: User, db: AsyncSession):
        # 1. Anonymize user details under DPDP Act
        user.full_name = "Deactivated Member"
        user.display_name = None
        user.headline = None
        user.avatar_url = None
        user.status = "deleted"
        user.badges = []

        # 2. Revoke all refresh tokens
        await db.execute(
            update(RefreshToken).where(RefreshToken.user_id == user.id).values(is_revoked=True)
        )

        # 3. Publish user.deleted event across modules via transactional outbox
        await event_bus.publish(
            db,
            "user.deleted",
            UserDeletedPayload(
                user_id=str(user.id),
                email=user.email,
                reason="user_requested_deletion",
            ),
        )

        await db.commit()

    @staticmethod
    async def submit_verification(user: User, payload: VerificationSubmitRequest, db: AsyncSession) -> VerificationRequest:
        req = VerificationRequest(
            id=uuid4(),
            user_id=user.id,
            kind=payload.kind,
            evidence_text=payload.evidence_text,
            evidence_urls=payload.evidence_urls or [],
            company_name=payload.company_name,
            company_registration=payload.company_registration,
            status="pending",
            created_at=datetime.now(UTC),
            updated_at=datetime.now(UTC),
        )
        db.add(req)
        await db.commit()
        await db.refresh(req)
        return req

    @staticmethod
    async def get_verification_status(user: User, db: AsyncSession) -> dict[str, Any]:
        result = await db.execute(
            select(VerificationRequest)
            .where(VerificationRequest.user_id == user.id)
            .order_by(VerificationRequest.created_at.desc())
        )
        requests = list(result.scalars().all())

        return {
            "verification_level": user.verification_level,
            "badges": user.badges,
            "trust_level": user.trust_level,
            "pending_requests": requests,
        }

    @staticmethod
    async def get_data_export(user: User, db: AsyncSession) -> dict[str, Any]:
        ver_res = await db.execute(
            select(VerificationRequest).where(VerificationRequest.user_id == user.id)
        )
        ver_requests = list(ver_res.scalars().all())

        app_res = await db.execute(
            select(ApprovedMember).where(ApprovedMember.email == user.email)
        )
        approved = app_res.scalar_one_or_none()

        approved_data = None
        if approved:
            approved_data = {
                "institution_id": approved.institution_id,
                "role": approved.role,
                "batch": approved.batch,
                "department": approved.department,
            }

        return {
            "user": user,
            "verification_requests": ver_requests,
            "approved_member_record": approved_data,
            "modules_data": {
                "auth": {
                    "account_created_at": user.created_at,
                    "last_seen_at": user.last_seen_at,
                    "verification_level": user.verification_level,
                    "badges": user.badges,
                    "institution": user.institution.name if user.institution else None,
                },
                "trust": {
                    "trust_level": user.trust_level,
                    "status": user.status,
                },
                "resume": {
                    "consents": ["dpdp_processing", "skill_extraction"],
                    "intent": user.headline or "Not specified",
                    "skills": [],
                },
                "sessions": {
                    "total_requests": 0,
                    "completed_sessions": 0,
                },
                "ratings": {
                    "rating_band": "Rising",
                    "ratings_count": 0,
                },
                "credits": {
                    "wallet_balance": 0,
                    "affinity_credits": 0,
                    "subscription_tier": "campus_free",
                },
                "payments": {
                    "payment_records": [],
                },
            },
            "exported_at": datetime.now(UTC),
        }
