"""
Module descriptor for 'matching'
Owner: M2
"""

from app.modules.matching.router import router as ROUTER

def register_events(bus):
    """Register outbox event handlers for matching."""
    pass

def register_ports(registry):
    """Register synchronous ports implemented by matching."""
    pass
