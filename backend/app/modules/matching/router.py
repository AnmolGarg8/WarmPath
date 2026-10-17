from fastapi import APIRouter, WebSocket, Request, Response
from app.core.errors import ModuleNotImplemented

router = APIRouter(tags=["matching"])

@router.get("/recommendations", summary="Get ranked mentor recommendations for student")
async def get_recommendations():
    raise ModuleNotImplemented("/recommendations")

@router.get("/givers/{id}", summary="View giver mentorship profile")
async def get_givers_id():
    raise ModuleNotImplemented("/givers/{id}")

@router.put("/me/giver-profile", summary="Update own giver mentorship profile and topics")
async def put_me_giver_profile():
    raise ModuleNotImplemented("/me/giver-profile")

@router.get("/me/giver-profile", summary="Retrieve own giver mentorship profile")
async def get_me_giver_profile():
    raise ModuleNotImplemented("/me/giver-profile")
