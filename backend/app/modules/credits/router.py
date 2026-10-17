from fastapi import APIRouter
from app.core.errors import ModuleNotImplemented

router = APIRouter(tags=["credits"])


@router.get("/plans")
async def get_plans():
    raise ModuleNotImplemented("GET /plans")


@router.get("/me/subscription")
async def get_my_subscription():
    raise ModuleNotImplemented("GET /me/subscription")


@router.get("/me/wallet")
async def get_my_wallet():
    raise ModuleNotImplemented("GET /me/wallet")


@router.get("/me/earnings")
async def get_my_earnings():
    raise ModuleNotImplemented("GET /me/earnings")


@router.post("/me/cashout")
async def cashout_credits():
    raise ModuleNotImplemented("POST /me/cashout")


@router.post("/me/donate-credits")
async def donate_credits():
    raise ModuleNotImplemented("POST /me/donate-credits")


@router.get("/sponsored-seats")
async def get_sponsored_seats():
    raise ModuleNotImplemented("GET /sponsored-seats")


@router.post("/admin/sponsored-seats")
async def allocate_sponsored_seats():
    raise ModuleNotImplemented("POST /admin/sponsored-seats")
