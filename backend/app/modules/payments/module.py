"""
Module descriptor for 'payments'
Owner: M4
"""

from app.modules.payments.router import router as ROUTER

def register_events(bus):
    """Register outbox event handlers for payments."""
    pass

def register_ports(registry):
    """Register synchronous ports implemented by payments."""
    pass
