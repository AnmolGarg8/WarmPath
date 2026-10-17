# Code Owners & Role Assignments

This document outlines the four member roles, assigned modules, and designated ownership areas.

| Role | Member Name | GitHub Handle | Module & Directory Ownership |
| :--- | :--- | :--- | :--- |
| **M1** | ANMOL GARG | @AnmolGarg8 | `backend/app/core`, modules `auth`, `trust`; `app/lib/core`, `app/lib/features/auth`, `features/safety`; `admin/src/core`, `admin/src/pages/moderation`, `pages/verification`; `scripts/`, `.github/`, root files, `PROJECT_CONTEXT.md` |
| **M2** | TANUSH YADAV | @Tanushyadav9 | backend modules `resume`, `matching`; `app/lib/features/onboarding`, `features/discover` |
| **M3** | AYUSH GHANSHALA | <!-- TODO: add M3 GitHub handle --> | backend modules `availability`, `sessions`, `ratings`; `app/lib/features/availability`, `features/sessions`, `features/ratings` |
| **M4** | SNEHA SINHA | <!-- TODO: add M4 GitHub handle --> | backend modules `credits`, `payments`, `institution`; `app/lib/features/plans_wallet`; `admin/src/pages/dashboard`, `pages/seats` |

## Shared Core Invariants
- `backend/app/main.py`: Discovers module routers automatically. Not modified during feature tasks.
- `app/lib/app_router.dart`: Imports all feature routes statically once. Not modified during feature tasks.
- `contracts/`: Each module owns its own YAML fragment in `contracts/modules/<module>.yaml`.
