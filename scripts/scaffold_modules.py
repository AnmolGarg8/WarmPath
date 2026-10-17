#!/usr/bin/env python3
"""
scripts/scaffold_modules.py - Bootstraps the 10 backend modules and their contracts.
"""

import os
from pathlib import Path

MODULES = {
    "auth": {
        "owner": "M1",
        "description": "Authentication, OTP verification, user profiles, data export, and institution lookups.",
        "endpoints": [
            ("POST", "/auth/request-otp", "Request one-time password for email"),
            ("POST", "/auth/verify-otp", "Verify one-time password and receive tokens"),
            ("POST", "/auth/refresh", "Refresh access token"),
            ("POST", "/auth/logout", "Revoke active session token"),
            ("GET", "/me", "Retrieve current authenticated user profile"),
            ("PATCH", "/me", "Update authenticated user profile"),
            ("DELETE", "/me", "Request account and data deletion under DPDP Act"),
            ("GET", "/me/data-export", "Download personal data export"),
            ("GET", "/institutions", "List supported institutions"),
            ("POST", "/verification/submit", "Submit institutional credentials for verification"),
            ("GET", "/verification/status", "Check current verification status"),
        ],
    },
    "trust": {
        "owner": "M1",
        "description": "7-layer trust engine, moderation queues, reporting, blocking, and audit logs.",
        "endpoints": [
            ("POST", "/reports", "Submit a report against a user, message, or session"),
            ("POST", "/blocks", "Block a user from contacting or booking"),
            ("DELETE", "/blocks/{user_id}", "Unblock a previously blocked user"),
            ("GET", "/me/trust", "Retrieve current private trust score and safety limits"),
            ("GET", "/admin/moderation/queue", "List pending moderation reports"),
            ("POST", "/admin/moderation/{id}/resolve", "Resolve a moderation report"),
            ("GET", "/admin/verification/queue", "List pending verification submissions"),
            ("POST", "/admin/verification/{id}/decide", "Approve or reject a verification request"),
            ("POST", "/admin/approved-members/upload", "Upload institutional roster CSV"),
            ("GET", "/admin/audit-log", "Retrieve security audit trail"),
        ],
    },
    "resume": {
        "owner": "M2",
        "description": "Resume upload, Gemini JSON parsing, consent handling, and student intent prompt.",
        "endpoints": [
            ("POST", "/resume", "Upload resume PDF for extraction"),
            ("GET", "/resume/profile", "Retrieve parsed resume skills and entities"),
            ("PUT", "/resume/profile", "Update or correct parsed resume entities"),
            ("DELETE", "/resume", "Delete uploaded resume and extracted vectors"),
            ("PUT", "/me/intent", "Save 'what do you want next' intent prompt"),
            ("GET", "/me/intent", "Retrieve current student intent prompt"),
            ("GET", "/me/consents", "Retrieve DPDP consent records"),
            ("PUT", "/me/consents", "Update DPDP consent preferences"),
        ],
    },
    "matching": {
        "owner": "M2",
        "description": "Heuristic match scoring, recommendation feed, and giver profile discovery.",
        "endpoints": [
            ("GET", "/recommendations", "Get ranked mentor recommendations for student"),
            ("GET", "/givers/{id}", "View giver mentorship profile"),
            ("PUT", "/me/giver-profile", "Update own giver mentorship profile and topics"),
            ("GET", "/me/giver-profile", "Retrieve own giver mentorship profile"),
        ],
    },
    "availability": {
        "owner": "M3",
        "description": "Giver availability schedules, weekly capacity caps, online presence, and real-time status.",
        "endpoints": [
            ("PUT", "/me/availability", "Set weekly schedule and session capacity limit"),
            ("GET", "/me/availability", "Retrieve current availability schedule"),
            ("POST", "/me/online", "Open 30-minute instant connect window"),
            ("DELETE", "/me/online", "Close instant connect window"),
            ("GET", "/presence", "Check online and capacity status for givers"),
            ("WS", "/ws", "WebSocket connection for live presence updates"),
        ],
    },
    "sessions": {
        "owner": "M3",
        "description": "Mentorship request lifecycle, booking slots, in-app messaging, and call session rooms.",
        "endpoints": [
            ("POST", "/requests", "Submit mentorship request to a giver"),
            ("GET", "/requests", "List incoming or outgoing mentorship requests"),
            ("GET", "/requests/{id}", "Get request details and agenda"),
            ("POST", "/requests/{id}/accept", "Accept a mentorship request"),
            ("POST", "/requests/{id}/decline", "Decline a mentorship request"),
            ("GET", "/givers/{id}/slots", "List open booking slots for a giver"),
            ("POST", "/requests/{id}/messages", "Send message in request thread"),
            ("GET", "/requests/{id}/messages", "Get messages for a request thread"),
            ("POST", "/sessions/{id}/join", "Join in-app video/voice call session"),
            ("POST", "/sessions/{id}/leave", "Leave video/voice call session"),
            ("GET", "/sessions/{id}", "Get session details and duration"),
            ("GET", "/me/sessions", "List past and upcoming sessions"),
            ("POST", "/notifications/devices", "Register device token for push notifications"),
        ],
    },
    "ratings": {
        "owner": "M3",
        "description": "Post-session two-way ratings, smoothed averages, rating bands, and dispute flow.",
        "endpoints": [
            ("POST", "/sessions/{id}/rating", "Student rates session quality (1-5 + feedback)"),
            ("POST", "/sessions/{id}/request-quality", "Giver rates student preparation and request clarity"),
            ("POST", "/sessions/{id}/dispute", "Open dispute for abusive or low-effort session"),
            ("GET", "/givers/{id}/rating-summary", "Get public rating aggregate for giver"),
            ("GET", "/me/band", "Get current rating band (Rising, Trusted, Top Rated)"),
            ("GET", "/admin/disputes", "List pending session disputes"),
            ("POST", "/admin/disputes/{id}/resolve", "Resolve a session dispute"),
        ],
    },
    "credits": {
        "owner": "M4",
        "description": "Credit ledger, subscription plans, cashouts, and student scholarship pool.",
        "endpoints": [
            ("GET", "/plans", "List subscription plans and credit allowances"),
            ("GET", "/me/subscription", "Get authenticated user active subscription"),
            ("GET", "/me/wallet", "Get credit balance and transaction history"),
            ("GET", "/me/earnings", "Get earned credits and cashout availability"),
            ("POST", "/me/cashout", "Request cashout for earned session credits"),
            ("POST", "/me/donate-credits", "Donate earned credits to scholarship pool"),
            ("GET", "/sponsored-seats", "Check sponsored seat availability"),
            ("POST", "/admin/sponsored-seats", "Allocate sponsored seats for institution"),
        ],
    },
    "payments": {
        "owner": "M4",
        "description": "Razorpay test mode subscriptions, payment webhooks, and payout release.",
        "endpoints": [
            ("POST", "/subscriptions", "Create checkout subscription in Razorpay test mode"),
            ("POST", "/subscriptions/cancel", "Cancel current active subscription"),
            ("POST", "/webhooks/razorpay", "Handle Razorpay payment and refund webhooks"),
        ],
    },
    "institution": {
        "owner": "M4",
        "description": "College administrator web panel, skill-gap analysis, and network health metrics.",
        "endpoints": [
            ("GET", "/admin/dashboard/overview", "Overview of active sessions, response times, and fulfillment"),
            ("GET", "/admin/dashboard/skill-gap", "Analysis of in-demand student skills vs alumni supply"),
            ("GET", "/admin/dashboard/safety-summary", "Safety incident summary and moderation resolution rate"),
            ("GET", "/admin/dashboard/seats", "Usage metrics for sponsored seats and credits"),
        ],
    },
}


def build_modules():
    repo_root = Path(__file__).resolve().parent.parent
    backend_modules_dir = repo_root / "backend" / "app" / "modules"
    contracts_dir = repo_root / "contracts" / "modules"

    backend_modules_dir.mkdir(parents=True, exist_ok=True)
    contracts_dir.mkdir(parents=True, exist_ok=True)

    for mod_name, meta in MODULES.items():
        mod_dir = backend_modules_dir / mod_name
        mod_dir.mkdir(parents=True, exist_ok=True)
        (mod_dir / "migrations").mkdir(exist_ok=True)
        (mod_dir / "migrations" / ".gitkeep").touch()
        (mod_dir / "tests").mkdir(exist_ok=True)
        (mod_dir / "__init__.py").write_text(f'"""Module: {mod_name}"""\n', encoding="utf-8")

        # 1. module.py
        module_py = f'''"""
Module descriptor for '{mod_name}'
Owner: {meta["owner"]}
"""

from app.modules.{mod_name}.router import router as ROUTER

def register_events(bus):
    """Register outbox event handlers for {mod_name}."""
    pass

def register_ports(registry):
    """Register synchronous ports implemented by {mod_name}."""
    pass
'''
        (mod_dir / "module.py").write_text(module_py, encoding="utf-8")

        # 2. router.py
        routes_code = [
            'from fastapi import APIRouter, WebSocket, Request, Response',
            'from app.core.errors import ModuleNotImplemented',
            '',
            f'router = APIRouter(tags=["{mod_name}"])',
            '',
        ]
        for method, path, desc in meta["endpoints"]:
            func_name = path.replace("/", "_").replace("{", "").replace("}", "").replace("-", "_").strip("_")
            if method == "WS":
                routes_code.append(f'@router.websocket("{path}")')
                routes_code.append(f'async def ws_{func_name}(websocket: WebSocket):')
                routes_code.append('    await websocket.close(code=1000)')
            else:
                routes_code.append(f'@router.{method.lower()}("{path}", summary="{desc}")')
                routes_code.append(f'async def {method.lower()}_{func_name}():')
                routes_code.append(f'    raise ModuleNotImplemented("{path}")')
            routes_code.append('')

        (mod_dir / "router.py").write_text("\n".join(routes_code), encoding="utf-8")

        # 3. schemas.py
        schemas_py = f'''"""Pydantic schemas for {mod_name}."""
from pydantic import BaseModel
from typing import Optional, List, Dict, Any

class Base{mod_name.capitalize()}Schema(BaseModel):
    pass
'''
        (mod_dir / "schemas.py").write_text(schemas_py, encoding="utf-8")

        # 4. models.py
        models_py = f'''"""SQLAlchemy models for {mod_name}."""
from app.core.db import Base
from sqlalchemy import Column, Integer, String

# Module models will be defined here by {meta["owner"]}
'''
        (mod_dir / "models.py").write_text(models_py, encoding="utf-8")

        # 5. service.py
        service_py = f'''"""Business logic service for {mod_name}."""
class {mod_name.capitalize()}Service:
    def __init__(self):
        pass
'''
        (mod_dir / "service.py").write_text(service_py, encoding="utf-8")

        # 6. README.md
        readme_md = f'''# Module: {mod_name}

- **Owner**: {meta["owner"]}
- **Responsibilities**: {meta["description"]}
- **Migrations Branch**: `{mod_name}` (stored in `migrations/`)

## Contract Endpoints
'''
        for method, path, desc in meta["endpoints"]:
            readme_md += f"- `{method} {path}`: {desc}\n"
        (mod_dir / "README.md").write_text(readme_md, encoding="utf-8")

        # 7. tests/test_router.py
        test_py = f'''import pytest
from httpx import AsyncClient, ASGITransport
from app.main import app

@pytest.mark.asyncio
async def test_{mod_name}_endpoints_return_501():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
'''
        # Add test for first HTTP endpoint
        first_http = next(((m, p) for m, p, _ in meta["endpoints"] if m != "WS"), None)
        if first_http:
            m, p = first_http
            test_path = p.replace("{id}", "123").replace("{user_id}", "123")
            test_py += f'''        response = await client.{m.lower()}("{test_path}")
        assert response.status_code == 501
        data = response.json()
        assert data["error"]["code"] == "module_not_implemented"
'''
        else:
            test_py += '        pass\n'
        (mod_dir / "tests" / "test_router.py").write_text(test_py, encoding="utf-8")

        # 8. contracts/modules/<module>.yaml
        contract_yaml = f"""paths:\n"""
        for method, path, desc in meta["endpoints"]:
            if method == "WS":
                continue
            contract_yaml += f"""  {path}:\n    {method.lower()}:\n      summary: "{desc}"\n      responses:\n        "501":\n          description: Module not implemented\n          content:\n            application/json:\n              schema:\n                $ref: '#/components/schemas/ErrorResponse'\n"""

        (contracts_dir / f"{mod_name}.yaml").write_text(contract_yaml, encoding="utf-8")

    print("All 10 modules and contracts scaffolded successfully.")


if __name__ == "__main__":
    build_modules()
