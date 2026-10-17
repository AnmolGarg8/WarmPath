"""
Module descriptor for 'auth'
Owner: M1
"""




from app.modules.auth.router import router as ROUTER

__all__ = ["ROUTER", "register_events", "register_ports"]


def register_events(bus):
    """Register outbox event handlers for auth."""


def register_ports(registry):
    """Register synchronous ports implemented by auth."""

