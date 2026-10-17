"""
Module descriptor for 'resume'
Owner: M2
"""

from app.modules.resume.router import router as ROUTER

def register_events(bus):
    """Register outbox event handlers for resume."""
    pass

def register_ports(registry):
    """Register synchronous ports implemented by resume."""
    pass
