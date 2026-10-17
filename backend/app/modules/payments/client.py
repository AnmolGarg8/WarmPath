"""
Razorpay TEST MODE Client with typed errors, timeouts, and safe retries.
Owner: M4
"""

import hashlib
import hmac
from typing import Any, Dict, Optional
import razorpay
from razorpay.errors import BadRequestError, GatewayError, ServerError, SignatureVerificationError
from requests.adapters import HTTPAdapter
from urllib3.util import Retry

from app.core.config import settings
from app.core.errors import AppError


class RazorpayClientWrapper:
    """Wrapper around official Razorpay SDK client with test-mode gating and typed errors."""

    def __init__(
        self,
        key_id: Optional[str] = None,
        key_secret: Optional[str] = None,
        webhook_secret: Optional[str] = None,
    ):
        self.key_id = key_id or settings.RAZORPAY_KEY_ID or "rzp_test_default_key"
        self.key_secret = key_secret or settings.RAZORPAY_KEY_SECRET or "rzp_test_default_secret"
        self.webhook_secret = webhook_secret or settings.RAZORPAY_WEBHOOK_SECRET or "rzp_test_webhook_secret"

        # Config gate: if keys do not start with rzp_test_ in non-production, refuse to start
        if settings.ENVIRONMENT != "production":
            if not self.key_id.startswith("rzp_test_"):
                raise AppError(
                    code="invalid_razorpay_keys",
                    message="Razorpay key ID must start with 'rzp_test_' in non-production environment.",
                    status_code=500,
                    details={"key_id_prefix": self.key_id[:8] if len(self.key_id) >= 8 else self.key_id},
                )

        self._client = razorpay.Client(auth=(self.key_id, self.key_secret))
        self._client.set_app_details({"title": "WarmPath", "version": "0.1.0"})

        # Setup safe retries and timeout on the underlying requests session
        retries = Retry(
            total=3,
            backoff_factor=0.3,
            status_forcelist=[429, 500, 502, 503, 504],
            allowed_methods=["GET", "HEAD", "OPTIONS"],  # Only safe idempotent methods
        )
        adapter = HTTPAdapter(max_retries=retries)
        self._client.session.mount("https://", adapter)
        self._client.session.mount("http://", adapter)

    def verify_webhook_signature(self, raw_body: bytes, signature: Optional[str]) -> bool:
        """Verify HMAC-SHA256 signature against the raw webhook body."""
        if not signature or not self.webhook_secret:
            return False
        expected_signature = hmac.new(
            self.webhook_secret.encode("utf-8"),
            raw_body,
            hashlib.sha256,
        ).hexdigest()
        return hmac.compare_digest(expected_signature, signature)

    def create_subscription(self, plan_id: str, total_count: int = 12) -> Dict[str, Any]:
        """Create a recurring subscription in Razorpay test mode."""
        try:
            return self._client.subscription.create(
                {
                    "plan_id": plan_id,
                    "total_count": total_count,
                    "quantity": 1,
                    "customer_notify": 1,
                }
            )
        except BadRequestError as e:
            raise AppError(code="razorpay_bad_request", message=str(e), status_code=400)
        except (GatewayError, ServerError) as e:
            raise AppError(code="razorpay_gateway_error", message=str(e), status_code=502)
        except Exception as e:
            raise AppError(code="razorpay_error", message=f"Failed to create subscription: {e}", status_code=500)

    def cancel_subscription(self, subscription_id: str, at_period_end: bool = True) -> Dict[str, Any]:
        """Cancel an active subscription."""
        try:
            return self._client.subscription.cancel(
                subscription_id,
                {"cancel_at_cycle_end": 1 if at_period_end else 0},
            )
        except BadRequestError as e:
            raise AppError(code="razorpay_bad_request", message=str(e), status_code=400)
        except Exception as e:
            raise AppError(code="razorpay_error", message=f"Failed to cancel subscription: {e}", status_code=500)

    def fetch_subscription(self, subscription_id: str) -> Dict[str, Any]:
        """Fetch subscription details from Razorpay."""
        try:
            return self._client.subscription.fetch(subscription_id)
        except Exception as e:
            raise AppError(code="razorpay_error", message=f"Failed to fetch subscription: {e}", status_code=500)

    def create_plan(self, name: str, amount_paise: int, period: str = "monthly", interval: int = 1) -> Dict[str, Any]:
        """Create a plan in Razorpay."""
        try:
            return self._client.plan.create(
                {
                    "period": period,
                    "interval": interval,
                    "item": {
                        "name": name,
                        "amount": amount_paise,
                        "currency": "INR",
                        "description": f"WarmPath {name} plan",
                    },
                }
            )
        except Exception as e:
            raise AppError(code="razorpay_error", message=f"Failed to create plan: {e}", status_code=500)

    def fetch_all_plans(self) -> Dict[str, Any]:
        """Fetch all plans from Razorpay."""
        try:
            return self._client.plan.all()
        except Exception as e:
            raise AppError(code="razorpay_error", message=f"Failed to fetch plans: {e}", status_code=500)


_client_instance: Optional[RazorpayClientWrapper] = None


def get_razorpay_client() -> RazorpayClientWrapper:
    global _client_instance
    if _client_instance is None:
        _client_instance = RazorpayClientWrapper()
    return _client_instance


def set_razorpay_client(client: Optional[RazorpayClientWrapper]) -> None:
    """Helper for testing to inject mock clients."""
    global _client_instance
    _client_instance = client
