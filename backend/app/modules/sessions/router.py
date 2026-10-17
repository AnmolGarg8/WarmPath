import uuid
from fastapi import APIRouter
from app.core.errors import ModuleNotImplemented

router = APIRouter(tags=["sessions"])


@router.post("/requests")
async def create_request():
    raise ModuleNotImplemented("POST /requests")


@router.get("/requests")
async def list_requests():
    raise ModuleNotImplemented("GET /requests")


@router.get("/requests/{id}")
async def get_request(id: uuid.UUID):
    raise ModuleNotImplemented(f"GET /requests/{id}")


@router.post("/requests/{id}/accept")
async def accept_request(id: uuid.UUID):
    raise ModuleNotImplemented(f"POST /requests/{id}/accept")


@router.post("/requests/{id}/decline")
async def decline_request(id: uuid.UUID):
    raise ModuleNotImplemented(f"POST /requests/{id}/decline")


@router.get("/givers/{id}/slots")
async def get_giver_slots(id: uuid.UUID):
    raise ModuleNotImplemented(f"GET /givers/{id}/slots")


@router.get("/requests/{id}/messages")
async def get_request_messages(id: uuid.UUID):
    raise ModuleNotImplemented(f"GET /requests/{id}/messages")


@router.post("/requests/{id}/messages")
async def send_request_message(id: uuid.UUID):
    raise ModuleNotImplemented(f"POST /requests/{id}/messages")


@router.post("/sessions/{id}/join")
async def join_session(id: uuid.UUID):
    raise ModuleNotImplemented(f"POST /sessions/{id}/join")


@router.post("/sessions/{id}/leave")
async def leave_session(id: uuid.UUID):
    raise ModuleNotImplemented(f"POST /sessions/{id}/leave")


@router.get("/sessions/{id}")
async def get_session(id: uuid.UUID):
    raise ModuleNotImplemented(f"GET /sessions/{id}")


@router.get("/me/sessions")
async def get_my_sessions():
    raise ModuleNotImplemented("GET /me/sessions")


@router.post("/notifications/devices")
async def register_device():
    raise ModuleNotImplemented("POST /notifications/devices")
