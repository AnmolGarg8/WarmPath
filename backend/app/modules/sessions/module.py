"""
Module descriptor for 'sessions'
Owner: M3
"""

from app.modules.sessions.router import router as ROUTER

def register_events(bus):
    """Register outbox event handlers for sessions."""
    pass

def register_ports(registry):
    """Register synchronous ports implemented by sessions."""
    pass
