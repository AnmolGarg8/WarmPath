import uuid
from fastapi import APIRouter
from app.core.errors import ModuleNotImplemented

router = APIRouter(tags=["matching"])


@router.get("/recommendations")
async def get_recommendations():
    raise ModuleNotImplemented("GET /recommendations")


@router.get("/givers/{id}")
async def get_giver_by_id(id: uuid.UUID):
    raise ModuleNotImplemented(f"GET /givers/{id}")


@router.get("/me/giver-profile")
async def get_my_giver_profile():
    raise ModuleNotImplemented("GET /me/giver-profile")


@router.put("/me/giver-profile")
async def update_my_giver_profile():
    raise ModuleNotImplemented("PUT /me/giver-profile")
