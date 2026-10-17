import uuid
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional
from sqlalchemy import select, delete
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.errors import AppError
from app.core.events import event_bus, ResumeParsedPayload, ProfileUpdatedPayload
from app.modules.resume.models import Consent, StudentProfile, StudentIntent
from app.modules.resume.schemas import (
    ConsentUpdateItem,
    ConsentItemResponse,
    ConsentsListResponse,
    ParsedResumeData,
    StructuredIntent,
)
from app.modules.resume.storage import get_storage_driver
from app.modules.resume.extractor import extract_resume_text
from app.modules.resume.parser import (
    RESUME_PARSER_SYSTEM_PROMPT,
    INTENT_STRUCTURING_SYSTEM_PROMPT,
    call_gemini_json,
    normalize_skills,
    generate_embedding,
)

VALID_CONSENT_PURPOSES = [
    "resume_processing",
    "profile_matching",
    "visibility_to_matched_givers",
]


class ResumeService:
    def __init__(self, session: AsyncSession):
        self.session = session
        self.storage = get_storage_driver()

    # --- Consent Operations (DPDP Act) ---

    async def get_consents(self, user_id: uuid.UUID) -> ConsentsListResponse:
        stmt = select(Consent).where(Consent.user_id == user_id)
        res = await self.session.execute(stmt)
        records = {c.purpose: c for c in res.scalars().all()}

        items = []
        for purpose in VALID_CONSENT_PURPOSES:
            c = records.get(purpose)
            if c:
                items.append(
                    ConsentItemResponse(
                        purpose=c.purpose,
                        granted=c.granted,
                        granted_at=c.granted_at,
                        withdrawn_at=c.withdrawn_at,
                        text_version=c.text_version,
                    )
                )
            else:
                items.append(
                    ConsentItemResponse(
                        purpose=purpose,
                        granted=False,
                        granted_at=None,
                        withdrawn_at=None,
                        text_version="v1.0",
                    )
                )
        return ConsentsListResponse(items=items)

    async def has_consent(self, user_id: uuid.UUID, purpose: str) -> bool:
        stmt = select(Consent).where(
            Consent.user_id == user_id,
            Consent.purpose == purpose,
            Consent.granted == True,
        )
        res = await self.session.execute(stmt)
        return res.scalar_one_or_none() is not None

    async def update_consents(
        self,
        user_id: uuid.UUID,
        consents: List[ConsentUpdateItem],
        text_version: str = "v1.0",
    ) -> ConsentsListResponse:
        now = datetime.now(timezone.utc)
        resume_processing_withdrawn = False

        for item in consents:
            if item.purpose not in VALID_CONSENT_PURPOSES:
                continue

            stmt = select(Consent).where(
                Consent.user_id == user_id,
                Consent.purpose == item.purpose,
            )
            res = await self.session.execute(stmt)
            record = res.scalar_one_or_none()

            if record:
                if not item.granted and record.granted:
                    record.granted = False
                    record.withdrawn_at = now
                    if item.purpose == "resume_processing":
                        resume_processing_withdrawn = True
                elif item.granted and not record.granted:
                    record.granted = True
                    record.granted_at = now
                    record.withdrawn_at = None
                record.text_version = text_version
            else:
                record = Consent(
                    user_id=user_id,
                    purpose=item.purpose,
                    granted=item.granted,
                    granted_at=now if item.granted else None,
                    withdrawn_at=None if item.granted else now,
                    text_version=text_version,
                )
                self.session.add(record)
                if not item.granted and item.purpose == "resume_processing":
                    resume_processing_withdrawn = True

        await self.session.flush()

        # If resume_processing is withdrawn, delete derived data
        if resume_processing_withdrawn:
            await self.delete_resume_data(user_id)

        await self.session.commit()
        return await self.get_consents(user_id)

    # --- Resume Upload and Parsing Pipeline ---

    async def process_resume_upload(
        self,
        user_id: uuid.UUID,
        file_bytes: bytes,
        original_filename: str,
    ) -> str:
        # 1. Enforce DPDP consent requirement
        if not await self.has_consent(user_id, "resume_processing"):
            raise AppError(
                code="consent_required",
                message="DPDP consent for 'resume_processing' is required prior to uploading a resume.",
                status_code=403,
            )

        # 2. Extract and validate format & contents
        doc_format, raw_text = extract_resume_text(file_bytes)

        # 3. Store file through storage driver
        resume_id = str(uuid.uuid4())
        filename = f"{user_id}_{resume_id}.{doc_format}"
        file_path = await self.storage.save(file_bytes, filename)

        # 4. Parse structured data using Gemini
        parsed_json = await call_gemini_json(RESUME_PARSER_SYSTEM_PROMPT, raw_text)

        # 5. Normalize skills against taxonomy
        normalized_skills = await normalize_skills(parsed_json.get("skills", []), self.session)
        parsed_json["skills"] = normalized_skills

        # 6. Generate embedding from skills and domains
        embedding_text = f"Skills: {', '.join(s['name'] for s in normalized_skills)}. Domains: {', '.join(parsed_json.get('domains', []))}. Experience: {parsed_json.get('experience_level', 'student')}"
        embedding = await generate_embedding(embedding_text)

        # 7. Upsert student_profile
        stmt = select(StudentProfile).where(StudentProfile.user_id == user_id)
        res = await self.session.execute(stmt)
        profile = res.scalar_one_or_none()

        now = datetime.now(timezone.utc)
        if profile:
            profile.raw_text = raw_text
            profile.resume_file_path = file_path
            profile.parsed = parsed_json
            profile.embedding = embedding
            profile.updated_at = now
        else:
            profile = StudentProfile(
                user_id=user_id,
                raw_text=raw_text,
                resume_file_path=file_path,
                parsed=parsed_json,
                edited=None,
                embedding=embedding,
                updated_at=now,
            )
            self.session.add(profile)

        # 8. Outbox events: resume.parsed and profile.updated
        await event_bus.publish(
            self.session,
            "resume.parsed",
            ResumeParsedPayload(
                user_id=str(user_id),
                skills_count=len(normalized_skills),
                projects_count=len(parsed_json.get("projects", [])),
            ),
        )
        await event_bus.publish(
            self.session,
            "profile.updated",
            ProfileUpdatedPayload(
                user_id=str(user_id),
                updated_fields=["skills", "education", "projects", "embedding"],
            ),
        )

        await self.session.commit()
        return resume_id

    # --- Student Profile Operations ---

    async def get_profile(self, user_id: uuid.UUID) -> Dict[str, Any]:
        stmt = select(StudentProfile).where(StudentProfile.user_id == user_id)
        res = await self.session.execute(stmt)
        profile = res.scalar_one_or_none()

        if not profile or not profile.parsed:
            raise AppError(
                code="profile_not_found",
                message="No resume profile found for this student. Please upload your resume first.",
                status_code=404,
            )

        merged = dict(profile.parsed)
        if profile.edited:
            merged.update({k: v for k, v in profile.edited.items() if v is not None})

        return {
            "user_id": profile.user_id,
            "parsed": profile.parsed,
            "edited": profile.edited,
            "merged": merged,
            "has_embedding": profile.embedding is not None,
            "updated_at": profile.updated_at,
        }

    async def update_profile(self, user_id: uuid.UUID, updates: Dict[str, Any]) -> Dict[str, Any]:
        stmt = select(StudentProfile).where(StudentProfile.user_id == user_id)
        res = await self.session.execute(stmt)
        profile = res.scalar_one_or_none()

        if not profile:
            raise AppError(
                code="profile_not_found",
                message="Profile not found. Please upload a resume first.",
                status_code=404,
            )

        current_edits = dict(profile.edited or {})
        for k, v in updates.items():
            if v is not None:
                current_edits[k] = v
        profile.edited = current_edits
        profile.updated_at = datetime.now(timezone.utc)

        # Merge and re-embed
        merged = dict(profile.parsed or {})
        merged.update(current_edits)

        skills = merged.get("skills", [])
        domains = merged.get("domains", [])
        skills_str = ", ".join(s["name"] if isinstance(s, dict) else str(s) for s in skills)
        domains_str = ", ".join(domains) if isinstance(domains, list) else str(domains)
        embed_text = f"Skills: {skills_str}. Domains: {domains_str}. Experience: {merged.get('experience_level', 'student')}"

        profile.embedding = await generate_embedding(embed_text)

        await event_bus.publish(
            self.session,
            "profile.updated",
            ProfileUpdatedPayload(
                user_id=str(user_id),
                updated_fields=list(updates.keys()) + ["embedding"],
            ),
        )

        await self.session.commit()
        return await self.get_profile(user_id)

    # --- Student Intent Operations ---

    async def get_intent(self, user_id: uuid.UUID) -> Dict[str, Any]:
        stmt = select(StudentIntent).where(StudentIntent.user_id == user_id)
        res = await self.session.execute(stmt)
        intent = res.scalar_one_or_none()

        if not intent:
            raise AppError(
                code="intent_not_found",
                message="No intent registered for this student yet.",
                status_code=404,
            )

        return {
            "user_id": intent.user_id,
            "raw_text": intent.raw_text,
            "goal_type": intent.goal_type,
            "target_roles": intent.target_roles or [],
            "target_domains": intent.target_domains or [],
            "structured": intent.structured,
            "has_embedding": intent.intent_embedding is not None,
            "updated_at": intent.updated_at,
        }

    async def update_intent(
        self,
        user_id: uuid.UUID,
        raw_text: str,
        goal_type: Optional[str] = "internship",
        target_roles: Optional[List[str]] = None,
        target_domains: Optional[List[str]] = None,
    ) -> Dict[str, Any]:
        # Structure intent via Gemini
        structured = await call_gemini_json(INTENT_STRUCTURING_SYSTEM_PROMPT, raw_text)

        # Generate intent embedding
        embed_text = f"Goal: {structured.get('goal', raw_text)}. Roles: {', '.join(structured.get('roles', []))}. Domains: {', '.join(structured.get('domains', []))}"
        embedding = await generate_embedding(embed_text)

        stmt = select(StudentIntent).where(StudentIntent.user_id == user_id)
        res = await self.session.execute(stmt)
        intent = res.scalar_one_or_none()

        now = datetime.now(timezone.utc)
        roles = target_roles or structured.get("roles", [])
        domains = target_domains or structured.get("domains", [])

        if intent:
            intent.raw_text = raw_text
            intent.goal_type = goal_type or structured.get("goal")
            intent.target_roles = roles
            intent.target_domains = domains
            intent.structured = structured
            intent.intent_embedding = embedding
            intent.updated_at = now
        else:
            intent = StudentIntent(
                user_id=user_id,
                raw_text=raw_text,
                goal_type=goal_type or structured.get("goal"),
                target_roles=roles,
                target_domains=domains,
                structured=structured,
                intent_embedding=embedding,
                updated_at=now,
            )
            self.session.add(intent)

        await event_bus.publish(
            self.session,
            "profile.updated",
            ProfileUpdatedPayload(
                user_id=str(user_id),
                updated_fields=["intent", "intent_embedding"],
            ),
        )

        await self.session.commit()
        return await self.get_intent(user_id)

    # --- Deletion and Data Purge ---

    async def delete_resume_data(self, user_id: uuid.UUID) -> None:
        stmt = select(StudentProfile).where(StudentProfile.user_id == user_id)
        res = await self.session.execute(stmt)
        profile = res.scalar_one_or_none()

        if profile:
            if profile.resume_file_path:
                await self.storage.delete(profile.resume_file_path)
            await self.session.delete(profile)

            await event_bus.publish(
                self.session,
                "profile.updated",
                ProfileUpdatedPayload(
                    user_id=str(user_id),
                    updated_fields=["resume_deleted", "embedding_deleted"],
                ),
            )
        await self.session.flush()

    async def purge_all_user_data(self, user_id: uuid.UUID) -> None:
        await self.delete_resume_data(user_id)
        await self.session.execute(delete(Consent).where(Consent.user_id == user_id))
        await self.session.execute(delete(StudentIntent).where(StudentIntent.user_id == user_id))
        await self.session.commit()
