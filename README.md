# WarmPath

> **Trust first, networking second.**  
> A closed, institution-verified, intent-first alumni network that replaces static directories with structured, high-signal connections.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![FastAPI](https://img.shields.io/badge/Backend-FastAPI-009688.svg?logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![Flutter](https://img.shields.io/badge/Mobile-Flutter-02569B.svg?logo=flutter&logoColor=white)](https://flutter.dev)
[![PostgreSQL](https://img.shields.io/badge/Database-PostgreSQL%20%2B%20pgvector-336791.svg?logo=postgresql&logoColor=white)](https://github.com/pgvector/pgvector)
[![Gemini](https://img.shields.io/badge/AI-Google%20Gemini%20API-4285F4.svg?logo=google&logoColor=white)](https://ai.google.dev)
[![Compliance](https://img.shields.io/badge/Compliance-DPDP%20Act%20Ready-green.svg)](#privacy--data-protection-dpdp-act)

---

## 📌 Executive Summary

Most alumni platforms fail because they treat alumni networks like **phonebooks**: static directories of hundreds of names where students send cold, vague messages into the void, and busy professionals get spammed until they turn off notifications.

Meanwhile, open professional platforms (like LinkedIn) are filled with unverified recruiters, fake job listings asking for "security deposits", and pressure to move conversations to private channels like WhatsApp or Telegram.

**WarmPath** is built on a simple thesis: **Building a Network, Not a Directory.**

1. **Resume-Driven & Intent-First**: Students don't search by company names or senior job titles. They upload their resume and answer one question: *"What do you want next?"* WarmPath pairs their skills and aspirations with alumni who have actually walked that path.
2. **Free Within College, Paid for Cross-College Reach**: Connecting with alumni from your own alma mater is always **100% free**. Students who want to reach domain experts, founders, and alumni across other institutions use a credit-based subscription where givers are fairly compensated.
3. **Earn by Merit, Not College Brand**: What an expert earns per session is governed strictly by **student ratings and review consistency**, not their college's prestige tier.
4. **7-Layer Trust & Fraud Shield**: Institution-backed identity verification, in-app audio/video calling (no phone numbers or personal emails exchanged), automated scam detection, and escrow-style protected payments.

---

## 🧭 The Core Problem

| Failure Mode Today | What Happens | The WarmPath Solution |
| :--- | :--- | :--- |
| **Cold, Blind Outreach** | Students have no network and don't know who to ask or how to draft a request. Cold DMs get ignored 98% of the time. | **Resume parsing + Intent matching**: An LLM structures the student's skills and intent into a clean, actionable intro line with a transparent "Why this person" match summary. |
| **Alumni Fatigue & Overload** | Busy alumni want to help, but get bombarded with open-ended messages ("Sir please refer me"). Helping has no boundary. | **Capacity limits & Instant windows**: Givers set strict weekly caps (e.g., max 2 calls/week) or toggle a 30-minute "Open Now" window. No routing beyond capacity. |
| **Passive College Directories** | Colleges invest in alumni databases (e.g., Almabase, Graduway) that end up as static lists. Admins have zero visibility into actual outcomes. | **Admin Intelligence Dashboard**: Real-time metrics on sessions completed, response times, feedback, and student-alumni skill gap analytics. |
| **Scams & Exploitation** | Fake recruiters prey on fresh graduates, demanding "registration fees", "training fees", or pushing to private chats. | **7-Layer Trust Engine**: Mandatory institutional / company verification, automated filters for money requests and Telegram/WhatsApp links, and fast human moderation. |
| **No Outcome Accountability** | Nobody knows if a mentorship session was genuinely helpful or a complete waste of time. | **Mandatory two-way ratings**: Rating unlocks payment escrow, feeds algorithmic ranking, and updates giver pay bands. |

---

## 🚀 Key Differentiators

```
  Traditional Platforms                     WarmPath Architecture
┌───────────────────────────┐             ┌───────────────────────────┐
│  Searchable Profile List  │             │  Resume + Intent Engine   │
│  Unverified Identities    │             │  Institution-Verified IDs │
│  Unregulated Cold DMs     │   ──────▶   │  Capped Capacity Windows  │
│  Pedigree-Biased Earnings │             │  Rating-Driven Pay Bands  │
│  External Unsafe Chats    │             │  Protected In-App Comms   │
└───────────────────────────┘             └───────────────────────────┘
```

- **Not Topmate / ADPList**: Topmate sells individual influencer time. WarmPath roots itself in verified college affinity first (free layer) and ties payouts to objective post-session ratings inside a closed credit economy.
- **Not LinkedIn**: Identity is verified against college roll lists and corporate registrations (CIN/GST). Unverified accounts cannot post opportunities or initiate outreach.
- **No "College Tier" Bias**: There are no "Tier 1 / Tier 2" labels. A giver from any college who consistently delivers high-value guidance earns top pay and priority ranking.

---

## 🛠️ How It Works (End-to-End)

```mermaid
sequenceDiagram
    autonumber
    actor Student as Student (Seeker)
    participant App as WarmPath Engine
    participant LLM as Gemini AI + pgvector
    actor Alum as Verified Alumnus (Giver)
    participant Escrow as Credit / Escrow Layer

    Student->>App: 1. Verified login (.edu / Roll No)
    Student->>App: 2. Upload Resume + State Intent ("What next?")
    App->>LLM: 3. Parse skills, domains & generate embeddings
    LLM-->>Student: 4. Editable profile + Matched Recommendations ("Why this match")
    
    alt Own-College Match
        Student->>Alum: 5a. Free Request (within Alumnus weekly capacity)
    else Cross-College / Expert Match
        Student->>Escrow: 5b. Reserve Subscription Credit
        Escrow-->>Alum: 5c. Notify session request with clear agenda
    end

    Alum->>App: 6. Accept request / Schedule slot (or "Connect Now")
    App->>App: 7. Embedded Video/Voice Call (Contacts masked)
    
    Student->>App: 8. Rate session (1-5 Stars + Feedback)
    Alum->>App: 9. Rate request quality
    App->>Escrow: 10. Release giver payout share / credit
```

### 1. Seeker Journey (Students)
1. **Verification**: Sign up using verified institutional email or roll/enrolment ID against an institution-cleared roster.
2. **Resume Parsing & Consent (DPDP Act)**: The student uploads a resume. An LLM parses skills, project areas, and domains into a structured JSON representation. The student can review and edit all extracted details before anything is saved.
3. **Intent Definition**: Answer one clear question: *"What do you want next?"* (e.g., *Frontend internship at an early-stage startup*, *GRE prep for MS in CS*, *Switching from Mechanical to Analytics*).
4. **Transparent Recommendations**: The system presents recommended alumni with a plain-language explanation (`"Matched because: Same department + React/Node project overlap + Alumnus offered startup mentoring"`).
5. **Connection & Scheduling**:
   - **Own-college alumni**: Always free, bounded by the alumnus's weekly capacity.
   - **Cross-college alumni & experts**: Booked using monthly subscription credits.
   - **Instant Connect**: If an alumnus has toggled their 30-minute "Open Now" window, connect immediately.
6. **Masked In-App Session**: Audio/video calls and chat happen entirely within the app. Personal phone numbers and emails are never exposed.
7. **Mutual Rating & Review**: The student rates the session quality (1–5 stars + review). The alumnus rates the student's preparation, incentivizing clear intents and polite communication.

### 2. Giver Journey (Alumni, Founders, Faculty, Recruiters)
1. **Identity Verification**: Verified via alumni cell records, work email domain, or portfolio proof.
2. **Boundary Controls**: Set weekly session limits (e.g., *3 sessions per week*) and optional ad-hoc availability windows. Givers are never overwhelmed by open-ended backlogs.
3. **Structured Inbound**: Givers receive pre-structured requests with the student's background summary and specific question, eliminating vague "Can we chat?" messages.
4. **Compensated Value**: For cross-college sessions, givers earn competitive payouts based on their rating tier. Earnings can be cashed out, reinvested to consult other senior experts on the platform, or donated to the student scholarship pool.

---

## 🛡️ The 7-Layer Trust & Safety Architecture

Trust is not assumed at registration—it is verified at entry, monitored during interaction, and enforced with definitive consequences.

```
┌─────────────────────────────────────────────────────────────┐
│ 7. CONTINUOUS LEARNING   Post-mortems update detection rules│
├─────────────────────────────────────────────────────────────┤
│ 6. HUMAN REVIEW          Named moderators & 24hr SLA queues │
├─────────────────────────────────────────────────────────────┤
│ 5. ABUSE & SCAM FILTER   Real-time regex & NLP for pay/links│
├─────────────────────────────────────────────────────────────┤
│ 4. IN-APP COMMUNICATION  Zero exposure of personal PII      │
├─────────────────────────────────────────────────────────────┤
│ 3. GRADUATED PRIVILEGES  Trust scores govern action limits  │
├─────────────────────────────────────────────────────────────┤
│ 2. LAYERED BADGES        Verified Student, Alumnus, Employer│
├─────────────────────────────────────────────────────────────┤
│ 1. IDENTITY AT ENTRY     College roster, roll number, GST   │
└─────────────────────────────────────────────────────────────┘
```

1. **Identity at Entry**:
   - Students & Alumni: Institution email verified against official rolls or alumni-cell rosters.
   - Recruiters & Founders: Company-domain email plus mandatory business registry validation (CIN / GST).
2. **Layered Badges**: Distinct badges visible across profiles: `Verified Student`, `Verified Alumnus`, `Verified Employer`, `Verified Expert`.
3. **Graduated Privileges**: New accounts operate under constrained rate limits (messages/day, no job posting, no paid hosting) until a track record of completed, well-rated interactions is established.
4. **In-App Communication Sandbox**: Communication remains strictly in-app. Phone numbers, personal WhatsApp handles, and personal emails are redacted.
5. **Real-Time Scam Detection**: Messages containing keywords associated with employment fraud (`registration fee`, `security deposit`, `processing fee`, `payment required`, `join Telegram`) are blocked instantly with warning banners and routed to the moderation desk.
6. **Fast Human Review & Sanctions**: Built-in 1-tap reporting on every profile, session, and message thread. Verified repeat offenders face permanent expulsion across both email and institutional enrolment identifiers.
7. **Post-Mortem Loop**: Incident post-mortems immediately generate updated detection heuristics and behavioral rules.

---

## ⚖️ The Economic Model & Fairness Guarantee

### Why Charging for Cross-College Reach is Not "Pay-to-Network"

- **Every student gets free access** to their own college's alumni base. That baseline never costs a cent.
- Busy senior engineers, founders, and recruiters outside one's college have severe opportunity costs. Paying givers for cross-college sessions turns polite declines into willing mentors.
- **No Pedigree Pricing**: Payout shares are tied exclusively to student satisfaction ratings:

| Giver Rating Band | Minimum Requirement | Illustrative Payout Share | Giver Payout (per ₹250 session credit) |
| :--- | :--- | :---: | :---: |
| **Rising** | Baseline verified profile | 60% | ₹150 |
| **Trusted** | Consistent 4.2+ rating (min. 5 sessions) | 70% | ₹175 |
| **Top Rated** | Consistent 4.7+ rating (high volume) | 80% | ₹200 |

*Note: Figures are illustrations for economics modeling. Platform margin covers infrastructure, video relays, verification checks, and escrow payment gateway fees.*

### Protected Payments & Escrow Mechanism
- **Credit Reservation**: Credits are held in escrow when a session is booked.
- **Automatic Refund Guarantee**: If a giver fails to respond within **72 hours** or misses a booked session, the student's credit is automatically refunded.
- **No-Show Protection**: If a student fails to attend a confirmed slot without notice, the credit is consumed to protect the giver's reserved time.
- **Scholarship Pool**: Alumni can choose to donate their session earnings directly to a subsidized credit pool for underprivileged students.

---

## 🧠 The Recommendation Engine (v1 Heuristic)

WarmPath Version 1 utilizes a transparent, explainable heuristic scoring function rather than a black-box model. Every score can be justified to the student:

$$\text{Match Score} = 0.35(E) + 0.25(I) + 0.15(A) + 0.10(C) + 0.10(R) + 0.05(O)$$

| Component | Weight | Signal Source | Why It Matters |
| :--- | :---: | :--- | :--- |
| **Expertise Fit ($E$)** | **35%** | Resume skills & project vector cosine similarity (`pgvector`) | Technical & domain relevance |
| **Intent Fit ($I$)** | **25%** | Match between student's *"What next?"* query and giver's offered topics | Focuses on where the student is heading, not just where they were |
| **Affinity ($A$)** | **15%** | Shared college, department, student society, or graduation batch | Warmth factor and natural rapport |
| **Availability ($C$)** | **10%** | Online-now flag, open time windows, remaining weekly bandwidth | Prioritizes givers who can respond immediately |
| **Rating Band ($R$)** | **10%** | Bayesian-smoothed session rating and completion rate | Elevates consistently helpful mentors |
| **Response Odds ($O$)** | **5%** | Historical acceptance speed and reply percentage | Prevents inquiries from hitting dead inboxes |

> **Hard Gate**: Accounts that are unverified, restricted by moderation, or currently at 100% capacity are **strictly filtered out** prior to scoring.

---

## 🏛️ Institutional Admin Dashboard

Universities and college placement cells partner with WarmPath to gain unprecedented, compliant insight into their community's career trajectories:

- **Engagement Analytics**: Requests posted, fulfillment rates, average response turnaround.
- **Skill-Gap Heatmap**: Aggregate analysis of what skills students are seeking vs. what current alumni offer—informing curriculum enhancements and targeted alumni outreach.
- **Sponsored Seat Allocation**: Administration of institutional grants and CSR-sponsored credits for eligible students.
- **Safety & Moderation Audit**: Real-time visibility into reported incidents, resolution times, and network health.
- **Data Sovereignty**: The institution retains ownership of its institutional data under clear DPDP-compliant data processing agreements.

---

## 💻 Tech Stack & Architecture

```
┌────────────────────────────────────────────────────────┐
│                   CLIENT LAYER                         │
│   Flutter Mobile App (iOS / Android)  │  Web Admin     │
└───────────────────────────┬────────────────────────────┘
                            │ REST / WebSocket
┌───────────────────────────▼────────────────────────────┐
│                  FASTAPI BACKEND                       │
│  ┌──────────────┐ ┌──────────────┐ ┌────────────────┐  │
│  │ Auth & Trust │ │ Resume/Parse │ │ Match & Rank   │  │
│  └──────────────┘ └──────────────┘ └────────────────┘  │
│  ┌──────────────┐ ┌──────────────┐ ┌────────────────┐  │
│  │ Book & Call  │ │ Escrow/Pay   │ │ ModerationDesk │  │
│  └──────────────┘ └──────────────┘ └────────────────┘  │
└─────────────┬──────────────────────────────┬───────────┘
              │                              │
┌─────────────▼──────────────┐ ┌─────────────▼───────────┐
│     DATA & STATE           │ │     EXTERNAL SERVICES   │
│  PostgreSQL + pgvector     │ │  Google Gemini 1.5 API  │
│  Redis (Presence & Cache)  │ │  Razorpay Payment Engine│
│  MinIO / S3 (Encrypted Doc)│ │  Google Calendar / Meet │
└────────────────────────────┘ └─────────────────────────┘
```

| Layer | Technology | Role in WarmPath |
| :--- | :--- | :--- |
| **Mobile Client** | **Flutter / Dart** | Single unified cross-platform mobile client for students and givers. |
| **Admin Web Portal** | **React / Next.js / Flutter Web** | Institution administration, verification queues, and analytics. |
| **API Services** | **FastAPI (Python 3.11+)** | High-performance asynchronous API for auth, matching, scheduling, and chat. |
| **Relational & Vector DB** | **PostgreSQL + pgvector** | User records, encrypted profiles, and high-dimensional semantic embeddings. |
| **Cache & Real-Time** | **Redis** | Online presence ("Open Now" flags), session locks, and rate limiters. |
| **AI Intelligence** | **Google Gemini API** | Deterministic resume JSON parsing, query structuring, and safety scanning. |
| **Calling Infrastructure** | **WebRTC / Jitsi Meet** | In-app secure audio/video channels with masked caller identity. |
| **Payments & Escrow** | **Razorpay** | Subscription billing, credit reservation, and direct payouts (test mode in build). |
| **Push Notifications** | **Firebase Cloud Messaging (FCM)** | Real-time session alerts, 72-hour reminders, and rating notifications. |

---

## 🔒 Privacy & Data Protection (DPDP Act)

WarmPath is engineered around India's **Digital Personal Data Protection (DPDP) Act**:

- **Explicit Granular Consent**: Students provide explicit consent for resume parsing and specific mentorship usage.
- **Zero Public Indexing**: Resumes and contact information are never crawled, indexed, or surfaced to web search engines.
- **Role-Based Selective Visibility**: Resumes are only shared with a specific matched alumnus after the student formally requests a session.
- **Data Subject Rights**: One-click **Download My Data** and permanent **Delete My Account & Data** workflows.
- **Strict Data Segregation**: Institutional roster data remains strictly isolated.

---

## 📁 Repository Structure

```text
WarmPath/
├── .github/
│   └── workflows/              # CI/CD workflows for test & linting
├── backend/
│   ├── app/
│   │   ├── api/                # API routes (auth, matching, sessions, reports)
│   │   ├── core/               # Configuration, security, database connectors
│   │   ├── models/             # SQLAlchemy / SQLModel database schemas
│   │   ├── services/           # Business logic
│   │   │   ├── parser.py       # Gemini resume parser & structuring
│   │   │   ├── matcher.py      # pgvector heuristic ranking algorithm
│   │   │   ├── trust.py        # 7-layer trust score & graduated limits
│   │   │   └── escrow.py       # Payment reservation and dispute lifecycle
│   │   └── main.py             # FastAPI entrypoint
│   ├── requirements.txt
│   └── Dockerfile
├── mobile/                     # Flutter mobile client
│   ├── lib/
│   │   ├── features/           # Feature modules (auth, explore, booking, call)
│   │   ├── shared/             # Common widgets, theme, networking
│   │   └── main.dart
│   └── pubspec.yaml
├── web-admin/                  # Institutional dashboard
├── docs/                       # Architectural specifications & pilot playbooks
├── docker-compose.yml          # Local container orchestration
└── README.md
```

---

## ⚡ Quickstart & Local Setup

### Prerequisites
- **Python 3.11+**
- **Flutter 3.19+**
- **Docker & Docker Compose**
- **Google Gemini API Key**

### 1. Clone & Setup Environment

```bash
git clone https://github.com/AnmolGarg8/WarmPath.git
cd WarmPath
```

Create a `.env` file in the `backend/` directory:

```env
PROJECT_NAME="WarmPath"
DATABASE_URL="postgresql://warmpath:secret@localhost:5432/warmpath_db"
REDIS_URL="redis://localhost:6379/0"
GEMINI_API_KEY="your-gemini-api-key"
JWT_SECRET="your-jwt-secret-key"
RAZORPAY_KEY_ID="rzp_test_xxxx"
RAZORPAY_KEY_SECRET="your_razorpay_secret"
```

### 2. Start Database & Infrastructure

```bash
docker compose up -d postgres redis
```

### 3. Launch Backend API

```bash
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: .\venv\Scripts\Activate.ps1
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```
Interactive API documentation will be available at `http://localhost:8000/docs`.

### 4. Launch Flutter App

```bash
cd ../mobile
flutter pub get
flutter run
```

---

## 🗺️ 90-Day Pilot Roadmap

WarmPath adheres to a strict single-college gate rule: *We do not expand to a second institution until the launch gates of the pilot college are satisfied.*

```
Days 1 - 30                 Days 31 - 60                Days 61 - 90
[ PREPARE ]                 [ OPEN TO STUDENTS ]        [ PROVE & SCALE ]
├── Onboard Alumni Cell     ├── Batch student invites   ├── Paid tier rollout
├── Seed 50 verified givers ├── Moderate flagged items  ├── Admin dashboard review
└── Legal & DPDP review     └── Track 72hr reply rate   └── Convert to annual license
```

- **Phase 1 (Days 1–30): Foundation & Seeding**
  - Partner with college alumni cell; ingest approved graduation roster.
  - Onboard and verify 50 initial alumni across diverse sectors.
  - Finalize legal policies, DPDP consent flows, and test-mode payment rails.
  - *Gate: 50 active verified givers ready; 0 critical vulnerabilities.*
- **Phase 2 (Days 31–60): Controlled Student Access**
  - Roll out access to students in batches of 100.
  - Hands-on moderation of all flagged interactions; fine-tune matching weights.
  - *Gate: $\ge 60\%$ of requests answered within 72 hours; zero unresolved serious disputes.*
- **Phase 3 (Days 61–90): Verification of Value & Conversion**
  - Enable cross-college subscription features in closed pilot cohorts.
  - Present engagement and skill-gap reports to college leadership.
  - Transition pilot into a formal institutional subscription.

---

## 👥 The Team: Unsolved Loop

Built with pride by **Team Unsolved Loop** at **VIPS-TC**:

- **Anmol Garg**
- **Tanush Yadav**
- **Ayush Ghanshala**
- **Sneha Sinha**

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
