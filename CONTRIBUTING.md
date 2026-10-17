# WarmPath Contribution & Team Workflow

This repository uses a strict ownership model to allow four teammates to build backend modules, Flutter features, and React admin pages in parallel without merge collisions.

## 1. Ownership Map

| Role | Focus | Owns |
|---|---|---|
| **M1** | Platform, Auth, Trust, Safety, Admin Core, Integration | `backend/app/core`, modules `auth`, `trust`; `app/lib/core`, `app/lib/features/auth`, `features/safety`; `admin/src/core`, `admin/src/pages/moderation`, `pages/verification`; `scripts/`, `.github/`, root files, `PROJECT_CONTEXT.md` |
| **M2** | Resume Parsing, Matching, Discovery, Scalability | modules `resume`, `matching`; `app/lib/features/onboarding`, `features/discover` |
| **M3** | Availability, Requests, Sessions, Ratings, Deployment | modules `availability`, `sessions`, `ratings`; `app/lib/features/availability`, `features/sessions`, `features/ratings` |
| **M4** | Plans, Credits, Payments, Institution Dashboard | modules `credits`, `payments`, `institution`; `app/lib/features/plans_wallet`; `admin/src/pages/dashboard`, `pages/seats` |

Shared files (`app/main.py`, `app/lib/app_router.dart`, dependency files) are frozen after P0. Each backend module owns its own `migrations/` folder and OpenAPI contract fragment in `contracts/modules/<module>.yaml`.

---

## 2. Daily Routine

### Set your identity once:
```bash
git config user.name "Your Real Name"
git config user.email "your-github-linked-email@example.com"
git config warmpath.member m2        # Set your role: m1, m2, m3, or m4
pre-commit install                   # Activates the scope guard hook
```

### Start a task (one branch per prompt):
```bash
git switch main && git pull --ff-only
git switch -c m2/b1-resume-parsing
```

### Work in small commits touching only your folders:
```bash
git add backend/app/modules/resume backend/app/modules/resume/migrations contracts/modules/resume.yaml
git commit -m "feat(resume): parse uploaded PDF into structured profile"
```

### Sync and open a Pull Request:
```bash
git fetch origin && git rebase origin/main
git push -u origin HEAD
gh pr create --fill
```

- Allowed merge method: **Rebase and merge only**.
- Never force-push `main`.
- If a teammate's module requires a change, do not edit it. Open a GitHub Issue labelled `needs:<role>` (e.g., `needs:m3`).

---

## 3. Review Pairs

- **M1** reviews **M2**
- **M2** reviews **M3**
- **M3** reviews **M4**
- **M4** reviews **M1**

---

## 4. Transparency & AI Tools Disclosure

AI coding assistants were used to accelerate prototyping and boilerplate generation. Every member is responsible for understanding, verifying, and testing their assigned modules.
