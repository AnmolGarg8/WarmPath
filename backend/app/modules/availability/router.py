from fastapi import APIRouter, WebSocket, Request, Response
from app.core.errors import ModuleNotImplemented

router = APIRouter(tags=["availability"])

@router.put("/me/availability", summary="Set weekly schedule and session capacity limit")
async def put_me_availability():
    raise ModuleNotImplemented("/me/availability")

@router.get("/me/availability", summary="Retrieve current availability schedule")
async def get_me_availability():
    raise ModuleNotImplemented("/me/availability")

@router.post("/me/online", summary="Open 30-minute instant connect window")
async def post_me_online():
    raise ModuleNotImplemented("/me/online")

@router.delete("/me/online", summary="Close instant connect window")
async def delete_me_online():
    raise ModuleNotImplemented("/me/online")

@router.get("/presence", summary="Check online and capacity status for givers")
async def get_presence():
    raise ModuleNotImplemented("/presence")

@router.websocket("/ws")
async def ws_ws(websocket: WebSocket):
    await websocket.close(code=1000)
