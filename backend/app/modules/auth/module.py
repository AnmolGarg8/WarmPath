"""
Module descriptor for 'auth'
Owner: M1
"""

from app.modules.auth.router import router as ROUTER

def register_events(bus):
    """Register outbox event handlers for auth."""
    pass

def register_ports(registry):
    """Register synchronous ports implemented by auth."""
    pass
