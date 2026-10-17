from fastapi import APIRouter, WebSocket, Request, Response
from app.core.errors import ModuleNotImplemented

router = APIRouter(tags=["resume"])

@router.post("/resume", summary="Upload resume PDF for extraction")
async def post_resume():
    raise ModuleNotImplemented("/resume")

@router.get("/resume/profile", summary="Retrieve parsed resume skills and entities")
async def get_resume_profile():
    raise ModuleNotImplemented("/resume/profile")

@router.put("/resume/profile", summary="Update or correct parsed resume entities")
async def put_resume_profile():
    raise ModuleNotImplemented("/resume/profile")

@router.delete("/resume", summary="Delete uploaded resume and extracted vectors")
async def delete_resume():
    raise ModuleNotImplemented("/resume")

@router.put("/me/intent", summary="Save 'what do you want next' intent prompt")
async def put_me_intent():
    raise ModuleNotImplemented("/me/intent")

@router.get("/me/intent", summary="Retrieve current student intent prompt")
async def get_me_intent():
    raise ModuleNotImplemented("/me/intent")

@router.get("/me/consents", summary="Retrieve DPDP consent records")
async def get_me_consents():
    raise ModuleNotImplemented("/me/consents")

@router.put("/me/consents", summary="Update DPDP consent preferences")
async def put_me_consents():
    raise ModuleNotImplemented("/me/consents")
