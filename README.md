# WarmPath

> **Trust first, networking second.**  
> A closed, institution-verified, intent-first alumni network that replaces static directories with structured, high-signal connections. Built by Team **Unsolved Loop (VIPS-TC)**.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Backend: FastAPI](https://img.shields.io/badge/Backend-FastAPI-009688.svg?logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![Client: Flutter](https://img.shields.io/badge/Mobile-Flutter-02569B.svg?logo=flutter&logoColor=white)](https://flutter.dev)
[![Admin: React](https://img.shields.io/badge/Admin-React%20%2B%20Vite-61DAFB.svg?logo=react&logoColor=black)](https://vitejs.dev)
[![Database: PostgreSQL + pgvector](https://img.shields.io/badge/Database-PostgreSQL%20%2B%20pgvector-336791.svg?logo=postgresql&logoColor=white)](https://github.com/pgvector/pgvector)

---

## 📌 Executive Summary

Most alumni platforms fail because they treat alumni networks like **phonebooks**: static directories of hundreds of names where students send cold, vague messages into the void, and busy professionals get spammed until they turn off notifications.

**WarmPath** is built on a clear thesis: **Building a Network, Not a Directory.**

1. **Resume-Driven & Intent-First**: Students upload their resume and answer one question: *"What do you want next?"* WarmPath extracts verified skills and intent to pair them with alumni who have walked that path.
2. **Free Within College, Paid for Cross-College Reach**: Connecting with alumni from your own college is **100% free**. Students who want to reach domain experts, founders, and alumni across other institutions use a credit-based subscription.
3. **Earn by Merit, Not College Brand**: What an expert earns per session is governed strictly by **student ratings and review consistency**, not by college prestige tiers.
4. **7-Layer Trust & Fraud Shield**: Institution-backed identity verification, in-app calling, automated scam detection, and escrow-style protected payments.

---

## 🏗️ Repository Architecture

This repository is organized as a zero-collision monorepo for a 4-person engineering team:

```text
warmpath/
├── backend/          # FastAPI modular monolith (Python 3.12, SQLAlchemy async, Alembic, arq)
├── app/              # Flutter mobile application (Riverpod, go_router, dio)
├── admin/            # React + Vite admin dashboard (Tailwind, TanStack Query)
├── contracts/        # Per-module OpenAPI specifications and contract validator
├── data/             # Reference seed CSV templates (institutions, approved members)
├── docs/             # Architecture, domain specifications, and trust documentation
├── scripts/          # Contributor reporting, migration helpers, scope guard, client generators
└── .github/          # CI/CD workflows and CODEOWNERS
```

---

## 👥 Module Ownership & Roles

| Role | Name | GitHub Handle | Owned Paths |
|---|---|---|---|
| **M1** (Platform Lead) | Tanush Yadav | `@Tanushyadav9` | `backend/app/core`, `modules/auth`, `modules/trust`; `app/lib/core`, `features/auth`, `features/safety`; `admin/src/core`, `pages/moderation`, `pages/verification`; `scripts/`, `.github/`, root docs |
| **M2** (Intelligence) | TBD | TBD | `backend/app/modules/resume`, `matching`; `app/lib/features/onboarding`, `discover` |
| **M3** (Sessions & Ratings) | TBD | TBD | `backend/app/modules/availability`, `sessions`, `ratings`; `app/lib/features/availability`, `sessions`, `ratings` |
| **M4** (Economy & Institution) | TBD | TBD | `backend/app/modules/credits`, `payments`, `institution`; `app/lib/features/plans_wallet`; `admin/src/pages/dashboard`, `seats` |

---

## 🚀 Quickstart & Local Setup

### 1. Prerequisites
- Docker & Docker Compose
- Python 3.12+
- Node.js 20+ & npm
- Flutter SDK (for mobile app development)

### 2. Bootstrap Local Services
Run the automated dev setup script:
```bash
bash scripts/setup-dev.sh
```

Or start the backend infrastructure manually:
```bash
docker compose up -d
```
Services exposed:
- **API Server:** [http://localhost:8000](http://localhost:8000) (Docs at `/docs`)
- **PostgreSQL + pgvector:** `localhost:5432`
- **Redis:** `localhost:6379`
- **Mailpit Web UI:** [http://localhost:8025](http://localhost:8025)

### 3. Run Backend Migrations & Tests
```bash
cd backend
alembic upgrade heads
pytest -q
```

### 4. Run Flutter Mobile App
```bash
cd app
flutter pub get
flutter run -d emulator-5554
```

### 5. Run Admin Panel
```bash
cd admin
npm install
npm run dev
```

---

## 🤖 Development Disclosure

AI coding assistants were used to accelerate boilerplate scaffolding, code generation, and test writing during the build. Every module, data model, security boundary, and business rule was reviewed, tested, and verified by its respective human module owner.

---

## 📄 License

Distributed under the MIT License. See [LICENSE](LICENSE) for more information.
