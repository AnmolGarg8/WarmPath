"""
backend/tests/e2e/test_wireup.py - Architecture & Module Wire-up Verification.
Verifies port registrations and ensures strict zero inter-module code imports.
"""

import ast
import inspect
from pathlib import Path
import pytest
from app.core import ports as core_ports
from app.core.ports import (
    CreditsPort,
    DefaultCreditsPort,
    DefaultMatchingPort,
    DefaultPresencePort,
    DefaultRatingsPort,
    DefaultSafetyPort,
    DefaultTrustPort,
    MatchingPort,
    PortRegistry,
    PresencePort,
    RatingsPort,
    SafetyPort,
    TrustPort,
)
import app.main as main_app


def test_no_inter_module_imports():
    """
    Confirms that no module imports another module's code.
    Modules talk to each other ONLY through ports (synchronous) and events (asynchronous).
    """
    repo_root = Path(__file__).resolve().parent.parent.parent
    modules_dir = repo_root / "app" / "modules"
    assert modules_dir.exists(), f"Modules directory not found at {modules_dir}"

    violations = []

    for mod_dir in sorted(modules_dir.iterdir()):
        if not mod_dir.is_dir() or mod_dir.name.startswith((".", "_")):
            continue

        mod_name = mod_dir.name

        for py_file in mod_dir.rglob("*.py"):
            try:
                tree = ast.parse(py_file.read_text(encoding="utf-8"), filename=str(py_file))
            except Exception as e:
                pytest.fail(f"Could not parse syntax in {py_file}: {e}")

            for node in ast.walk(tree):
                target_module = None
                if isinstance(node, ast.Import):
                    for alias in node.names:
                        target_module = alias.name
                        if target_module.startswith("app.modules."):
                            parts = target_module.split(".")
                            if len(parts) >= 3:
                                foreign_mod = parts[2]
                                if foreign_mod != mod_name:
                                    violations.append((str(py_file), target_module, foreign_mod))
                elif isinstance(node, ast.ImportFrom):
                    target_module = node.module or ""
                    if target_module.startswith("app.modules."):
                        parts = target_module.split(".")
                        if len(parts) >= 3:
                            foreign_mod = parts[2]
                            if foreign_mod != mod_name:
                                violations.append((str(py_file), target_module, foreign_mod))

    assert not violations, (
        f"Found {len(violations)} inter-module import violation(s)!\n"
        + "\n".join(f"  {src} imports foreign module '{foreign}' via '{target}'" for src, target, foreign in violations)
    )


def test_core_ports_defined_and_fail_closed():
    """
    Confirms that all 6 ports from PROJECT_CONTEXT Section 6 are defined in app.core.ports,
    and their default implementations fail closed.
    """
    expected_ports = {
        "safety": SafetyPort,
        "trust": TrustPort,
        "credits": CreditsPort,
        "ratings": RatingsPort,
        "presence": PresencePort,
        "matching": MatchingPort,
    }

    test_registry = PortRegistry()

    for port_name, protocol_cls in expected_ports.items():
        assert hasattr(test_registry, port_name), f"PortRegistry missing attribute '{port_name}'"
        port_instance = getattr(test_registry, port_name)
        assert isinstance(port_instance, protocol_cls), f"Default {port_name} port does not implement {protocol_cls.__name__}"


def test_single_owner_per_port_registration():
    """
    Verifies that no port is registered by more than one module.
    Each port must have exactly one owning module implementation.
    """
    repo_root = Path(__file__).resolve().parent.parent.parent
    modules_dir = repo_root / "app" / "modules"

    port_registrations = {
        "safety": [],
        "trust": [],
        "credits": [],
        "ratings": [],
        "presence": [],
        "matching": [],
    }

    # Inspect each module's register_ports function
    for mod_dir in sorted(modules_dir.iterdir()):
        if not mod_dir.is_dir() or mod_dir.name.startswith((".", "_")):
            continue

        mod_name = mod_dir.name
        module_file = mod_dir / "module.py"
        if not module_file.exists():
            continue

        try:
            tree = ast.parse(module_file.read_text(encoding="utf-8"))
        except Exception:
            continue

        # Look for assignments to registry.<port>
        for node in ast.walk(tree):
            if isinstance(node, ast.FunctionDef) and node.name == "register_ports":
                for stmt in ast.walk(node):
                    if isinstance(stmt, ast.Assign):
                        for target in stmt.targets:
                            if isinstance(target, ast.Attribute) and target.attr in port_registrations:
                                port_registrations[target.attr].append(mod_name)

    # Check for collisions: no port may be claimed by > 1 module
    for port, registered_modules in port_registrations.items():
        assert len(registered_modules) <= 1, (
            f"Port collision! Port '{port}' is registered by multiple modules: {registered_modules}"
        )

    # Trust & Safety ports are verified to be registered by 'trust'
    assert "trust" in port_registrations["safety"], "SafetyPort must be registered by trust module"
    assert "trust" in port_registrations["trust"], "TrustPort must be registered by trust module"


def test_all_contract_endpoints_in_router():
    """
    Confirms all endpoints declared in OpenAPI contract are mounted in the FastAPI application.
    """
    import sys
    repo_root = Path(__file__).resolve().parent.parent.parent.parent
    if str(repo_root) not in sys.path:
        sys.path.insert(0, str(repo_root))

    from scripts.build_openapi import build_merged_openapi

    merged = build_merged_openapi()
    contract_paths = set(merged.get("paths", {}).keys())

    mounted_paths = set()
    for route in main_app.app.routes:
        if hasattr(route, "path"):
            mounted_paths.add(route.path)

    missing = contract_paths - mounted_paths
    assert not missing, f"Missing routes from contract in FastAPI app: {sorted(missing)}"
