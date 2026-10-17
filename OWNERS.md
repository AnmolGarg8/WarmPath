# Code and Module Ownership Map

| Role | Member Name | GitHub Handle | Owned Paths |
|---|---|---|---|
| **M1** | Tanush Yadav | @Tanushyadav9 | `backend/app/core/`<br>`backend/app/modules/auth/`<br>`backend/app/modules/trust/`<br>`app/lib/core/`<br>`app/lib/features/auth/`<br>`app/lib/features/safety/`<br>`admin/src/core/`<br>`admin/src/pages/moderation/`<br>`admin/src/pages/verification/`<br>`scripts/`<br>`.github/`<br>`contracts/modules/auth.yaml`<br>`contracts/modules/trust.yaml`<br>Root config and documentation |
| **M2** | TBD | @GITHUB_M2 | `backend/app/modules/resume/`<br>`backend/app/modules/matching/`<br>`app/lib/features/onboarding/`<br>`app/lib/features/discover/`<br>`contracts/modules/resume.yaml`<br>`contracts/modules/matching.yaml` |
| **M3** | TBD | @GITHUB_M3 | `backend/app/modules/availability/`<br>`backend/app/modules/sessions/`<br>`backend/app/modules/ratings/`<br>`app/lib/features/availability/`<br>`app/lib/features/sessions/`<br>`app/lib/features/ratings/`<br>`contracts/modules/availability.yaml`<br>`contracts/modules/sessions.yaml`<br>`contracts/modules/ratings.yaml` |
| **M4** | TBD | @GITHUB_M4 | `backend/app/modules/credits/`<br>`backend/app/modules/payments/`<br>`backend/app/modules/institution/`<br>`app/lib/features/plans_wallet/`<br>`admin/src/pages/dashboard/`<br>`admin/src/pages/seats/`<br>`contracts/modules/credits.yaml`<br>`contracts/modules/payments.yaml`<br>`contracts/modules/institution.yaml` |

---

## Frozen Shared Files
The following files are pre-wired during **Prompt P0** and are frozen for the duration of parallel development:
- `backend/pyproject.toml`
- `backend/app/main.py`
- `app/pubspec.yaml`
- `app/lib/app_router.dart`
- `admin/package.json`
- `docker-compose.yml`

Changes to frozen files require consensus and an explicit PR reviewed by M1.
