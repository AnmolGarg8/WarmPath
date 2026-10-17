from fastapi import APIRouter, WebSocket
from app.core.errors import ModuleNotImplemented

router = APIRouter(tags=["availability"])


@router.get("/me/availability")
async def get_my_availability():
    raise ModuleNotImplemented("GET /me/availability")


@router.put("/me/availability")
async def update_my_availability():
    raise ModuleNotImplemented("PUT /me/availability")


@router.post("/me/online")
async def go_online():
    raise ModuleNotImplemented("POST /me/online")


@router.delete("/me/online")
async def go_offline():
    raise ModuleNotImplemented("DELETE /me/online")


@router.get("/presence")
async def get_presence():
    raise ModuleNotImplemented("GET /presence")


@router.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.close(code=1000, reason="WebSocket scaffolded - pending module implementation")
