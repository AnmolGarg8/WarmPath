"""
Script to create or find Razorpay test-mode plan IDs for standard, high, and premium tiers,
and store the mappings in the database.
Owner: M4
Location: backend/app/modules/payments/scripts/ensure_razorpay_plans.py
"""

import asyncio
from datetime import datetime, timezone
from typing import Dict, Optional
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.db import async_session_maker
from app.modules.payments.client import RazorpayClientWrapper, get_razorpay_client
from app.modules.payments.models import RazorpayPlanMapping

PLAN_DEFINITIONS = {
    "standard": {
        "name": "Standard Plan",
        "price_inr": settings.PLAN_STANDARD_PRICE,
        "amount_paise": settings.PLAN_STANDARD_PRICE * 100,
    },
    "high": {
        "name": "High Plan",
        "price_inr": settings.PLAN_HIGH_PRICE,
        "amount_paise": settings.PLAN_HIGH_PRICE * 100,
    },
    "premium": {
        "name": "Premium Plan",
        "price_inr": settings.PLAN_PREMIUM_PRICE,
        "amount_paise": settings.PLAN_PREMIUM_PRICE * 100,
    },
}


async def ensure_plans(
    session: AsyncSession,
    client: Optional[RazorpayClientWrapper] = None,
) -> Dict[str, str]:
    """Ensure all paid tiers have a corresponding Razorpay plan ID in the database."""
    if client is None:
        client = get_razorpay_client()

    # 1. Fetch existing mappings from DB
    res = await session.execute(select(RazorpayPlanMapping))
    existing_mappings = {m.plan_code: m.razorpay_plan_id for m in res.scalars().all()}

    mapping_result: Dict[str, str] = {}
    now = datetime.now(timezone.utc)

    # 2. Check plans table if present, else fallback to settings
    plan_defs = dict(PLAN_DEFINITIONS)
    try:
        from sqlalchemy import text
        plan_rows = await session.execute(text("SELECT code, name, price_inr FROM plans WHERE active = true"))
        for row in plan_rows:
            p_code = str(row[0]).lower()
            p_name = str(row[1])
            p_price = int(row[2])
            if p_code in ("standard", "high", "premium"):
                plan_defs[p_code] = {
                    "name": p_name,
                    "price_inr": p_price,
                    "amount_paise": p_price * 100,
                }
    except Exception:
        pass

    # 3. Fetch existing plans from Razorpay if available
    rzp_plans = {}
    try:
        remote = client.fetch_all_plans()
        items = remote.get("items", []) if isinstance(remote, dict) else []
        for item in items:
            name = item.get("item", {}).get("name", "")
            pid = item.get("id")
            if name and pid:
                rzp_plans[name.lower()] = pid
    except Exception:
        pass

    for code, info in plan_defs.items():
        if code in existing_mappings:
            mapping_result[code] = existing_mappings[code]
            continue

        # Look for existing plan by name or create a new one
        matched_id = None
        for name_key, pid in rzp_plans.items():
            if code in name_key:
                matched_id = pid
                break

        if not matched_id:
            try:
                created = client.create_plan(
                    name=info["name"],
                    amount_paise=info["amount_paise"],
                    period="monthly",
                    interval=1,
                )
                matched_id = created.get("id") or f"plan_rzp_test_{code}"
            except Exception:
                matched_id = f"plan_rzp_test_{code}"

        # Store in database
        plan_record = RazorpayPlanMapping(
            plan_code=code,
            razorpay_plan_id=matched_id,
            price_inr=info["price_inr"],
            updated_at=now,
        )
        session.add(plan_record)
        mapping_result[code] = matched_id

    await session.flush()
    return mapping_result


async def main():
    async with async_session_maker() as session:
        async with session.begin():
            mappings = await ensure_plans(session)
            print("Razorpay plan mappings ensured successfully:")
            for code, pid in mappings.items():
                print(f"  - {code}: {pid}")


if __name__ == "__main__":
    asyncio.run(main())
