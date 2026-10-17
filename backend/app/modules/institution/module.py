"""
Module descriptor for 'institution'
Owner: M4
"""

from app.modules.institution.router import router as ROUTER

def register_events(bus):
    """Register outbox event handlers for institution."""
    pass

def register_ports(registry):
    """Register synchronous ports implemented by institution."""
    pass
