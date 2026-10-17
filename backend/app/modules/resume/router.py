import uuid
from typing import Any, Dict
from fastapi import APIRouter, Depends, File, UploadFile, Request, status, Response
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.db import get_db
from app.core.security import decode_token
from app.modules.resume.service import ResumeService
from app.modules.resume.schemas import (
    UpdateConsentsRequest,
    ConsentsListResponse,
    ResumeUploadResponse,
    StudentProfileUpdateRequest,
    StudentProfileResponse,
    StudentIntentUpdateRequest,
    StudentIntentResponse,
)

router = APIRouter(tags=["resume"])


async def get_current_user_id(request: Request) -> uuid.UUID:
    auth_header = request.headers.get("Authorization")
    if auth_header and auth_header.startswith("Bearer "):
        token = auth_header[7:].strip()
        try:
            payload = decode_token(token)
            return uuid.UUID(payload["sub"])
        except Exception:
            pass

    x_user_id = request.headers.get("X-User-ID")
    if x_user_id:
        try:
            return uuid.UUID(x_user_id)
        except Exception:
            pass

    # Default dev test user
    return uuid.UUID("00000000-0000-0000-0000-000000000001")


# --- DPDP Consents Endpoints ---

@router.get("/me/consents", response_model=ConsentsListResponse, summary="Retrieve DPDP consent records")
async def get_consents(
    user_id: uuid.UUID = Depends(get_current_user_id),
    session: AsyncSession = Depends(get_db),
):
    service = ResumeService(session)
    return await service.get_consents(user_id)


@router.put("/me/consents", response_model=ConsentsListResponse, summary="Update DPDP consent preferences")
async def update_consents(
    req: UpdateConsentsRequest,
    user_id: uuid.UUID = Depends(get_current_user_id),
    session: AsyncSession = Depends(get_db),
):
    service = ResumeService(session)
    return await service.update_consents(user_id, req.consents, req.text_version or "v1.0")


# --- Resume Upload and Profile Endpoints ---

@router.post("/resume", response_model=ResumeUploadResponse, status_code=status.HTTP_202_ACCEPTED, summary="Upload resume PDF/DOCX for AI extraction")
async def upload_resume(
    file: UploadFile = File(...),
    user_id: uuid.UUID = Depends(get_current_user_id),
    session: AsyncSession = Depends(get_db),
):
    content = await file.read()
    service = ResumeService(session)
    resume_id = await service.process_resume_upload(user_id, content, file.filename or "resume.pdf")
    return ResumeUploadResponse(resume_id=resume_id, status="processing")


@router.get("/resume/profile", response_model=StudentProfileResponse, summary="Retrieve parsed and edited resume profile")
async def get_resume_profile(
    user_id: uuid.UUID = Depends(get_current_user_id),
    session: AsyncSession = Depends(get_db),
):
    service = ResumeService(session)
    return await service.get_profile(user_id)


@router.put("/resume/profile", response_model=StudentProfileResponse, summary="Update student profile edits and re-embed")
async def update_resume_profile(
    req: StudentProfileUpdateRequest,
    user_id: uuid.UUID = Depends(get_current_user_id),
    session: AsyncSession = Depends(get_db),
):
    service = ResumeService(session)
    updates = req.model_dump(exclude_unset=True)
    return await service.update_profile(user_id, updates)


@router.delete("/resume", status_code=status.HTTP_204_NO_CONTENT, summary="Delete uploaded resume, parsed data and embeddings")
async def delete_resume(
    user_id: uuid.UUID = Depends(get_current_user_id),
    session: AsyncSession = Depends(get_db),
):
    service = ResumeService(session)
    await service.delete_resume_data(user_id)
    await session.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


# --- Intent Endpoints ---

@router.get("/me/intent", response_model=StudentIntentResponse, summary="Retrieve structured intent and goal")
async def get_intent(
    user_id: uuid.UUID = Depends(get_current_user_id),
    session: AsyncSession = Depends(get_db),
):
    service = ResumeService(session)
    return await service.get_intent(user_id)


@router.put("/me/intent", response_model=StudentIntentResponse, summary="Save and structure 'what do you want next' intent")
async def update_intent(
    req: StudentIntentUpdateRequest,
    user_id: uuid.UUID = Depends(get_current_user_id),
    session: AsyncSession = Depends(get_db),
):
    service = ResumeService(session)
    return await service.update_intent(
        user_id=user_id,
        raw_text=req.text,
        goal_type=req.goal_type,
        target_roles=req.target_roles,
        target_domains=req.target_domains,
    )
