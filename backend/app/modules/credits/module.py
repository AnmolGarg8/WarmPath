"""
Module descriptor for 'credits'
Owner: M4
"""

from app.modules.credits.router import router as ROUTER

def register_events(bus):
    """Register outbox event handlers for credits."""
    pass

def register_ports(registry):
    """Register synchronous ports implemented by credits."""
    pass
