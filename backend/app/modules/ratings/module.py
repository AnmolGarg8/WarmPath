"""
Module descriptor for 'ratings'
Owner: M3
"""

from app.modules.ratings.router import router as ROUTER

def register_events(bus):
    """Register outbox event handlers for ratings."""
    pass

def register_ports(registry):
    """Register synchronous ports implemented by ratings."""
    pass
