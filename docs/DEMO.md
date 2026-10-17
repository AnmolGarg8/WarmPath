# WarmPath Live Demonstration Guide

## 1. Overview & Demonstration Principles
WarmPath presentations follow an **honest, real-execution model**:
- Every demo step runs against genuine backend services (FastAPI, PostgreSQL with pgvector, Redis, Arq worker, Mailpit, and Jitsi Meet).
- No placeholder cards, fake delays, or mock fixtures.
- The **Honest Demo Profile** (`DEMO_PROFILE=true`) shortens timers (e.g. 2-minute dispute window, 5-minute no-reply expiry) with transparent, persistent banners on both the mobile app and admin panel.

---

## 2. Preflight Health Verification
Before presenting to an evaluation panel or jury, run the automated preflight scanner:
```bash
python scripts/demo/preflight.py
```

### Preflight Checks Run:
1. **Docker Services**: Postgres, Redis, and Mailpit containers are active.
2. **Alembic Migrations**: All migration branches applied to head.
3. **Mailpit Web API**: Reachable at `http://localhost:8025` for live OTP inspection.
4. **SMTP Service**: SMTP daemon listening at `localhost:1025`.
5. **Gemini AI API**: Connectivity and quota verified with a lightweight ping.
6. **Razorpay Test Keys**: Valid `rzp_test_...` key ID, secret, and subscription plans mapped.
7. **Jitsi Meet Server**: Video call infrastructure reachable at `https://meet.jit.si`.
8. **FCM Credentials**: Service account JSON present if push notifications are enabled.
9. **Seed Data Loaded**: Institutions, approved members, and skills taxonomy present in database.
10. **Verified Alumni Givers**: At least N active, verified alumni with capacity (default: 5).
11. **Demo Profile Configuration**: `DEMO_PROFILE=true` matches presentation intent.
12. **ADB Emulators**: Required Android virtual devices running (`emulator-5554` and `emulator-5556`).

### Options & Flags:
- `--min-givers N`: Specify minimum required verified alumni (default: 5).
- `--no-emulators`: Run preflight in backend-only headless mode.
- `--prod`: Verify production configuration (`DEMO_PROFILE=false`) rather than demo mode.

---

## 3. Database Snapshot & Restoration (`db_snapshot`)
A live demonstration modifies database records (accepts mentorship requests, reserves credits, records call logs, and transitions rating bands).
To return to a known-good state before each rehearsal or presentation:

### PowerShell (Windows):
```powershell
# Save a clean baseline snapshot
powershell scripts/demo/db_snapshot.ps1 -Action save

# Restore to the latest clean baseline
powershell scripts/demo/db_snapshot.ps1 -Action restore

# List available snapshots
powershell scripts/demo/db_snapshot.ps1 -Action list
```

### Bash (macOS / Linux / Git Bash):
```bash
# Save snapshot
bash scripts/demo/db_snapshot.sh save

# Restore to latest snapshot
bash scripts/demo/db_snapshot.sh restore

# List snapshots
bash scripts/demo/db_snapshot.sh list
```

### Safety Refusal Guard:
`db_snapshot` validates the target connection string using `scripts/demo/db_safety.py`. It **refuses** execution if the database host is not `localhost`, `127.0.0.1`, or `postgres`, or if the database name does not contain `warmpath`, preventing accidental overwrites of staging or production databases.

---

## 4. 10-Minute Pre-Demo Routine
Follow this checklist starting 10 minutes before presenting:

- **T-10m: Clean Baseline**
  Restore the database to the known-good demo snapshot:
  ```powershell
  powershell scripts/demo/db_snapshot.ps1 -Action restore
  ```

- **T-8m: Infrastructure Verification**
  Confirm backend containers are healthy:
  ```powershell
  cd backend; docker compose up -d
  ```

- **T-6m: Emulator Initialization**
  Launch both required Android emulators and confirm ADB connection:
  ```powershell
  adb devices
  # Output should list: emulator-5554 and emulator-5556
  ```

- **T-5m: Automated Preflight**
  Run the preflight health check:
  ```powershell
  python scripts/demo/preflight.py
  # Verify OVERALL PREFLIGHT: PASS (12/12 checks passed)
  ```

- **T-3m: App Launch & Banner Check**
  Open the WarmPath app on both emulators (`emulator-5554` for student, `emulator-5556` for giver).
  Confirm the persistent top banner is visible:
  > *Demo profile: timers are shortened for the demo*

- **T-2m: Browser Staging**
  Open side-by-side browser tabs:
  - Mailpit UI: `http://localhost:8025` (to show incoming OTPs live).
  - Admin Panel: `http://localhost:5173` (to show audit logs & moderation).

- **T-0m: Ready to Present.**

---

---

# WarmPath 4-Minute Live Demo Script & Jury Defense

> **Theme**: Alumni Network and Professional Connections: Building a Network, Not a Directory.  
> **Team**: Unsolved Loop (VIPS-TC)  
> **Product**: WarmPath - Trusted, Intent-First, Rating-Powered Alumni Mentorship Platform  

---

## 1. Demo Overview & Guidelines

- **Duration**: Exactly 4 minutes (240 seconds)
- **Golden Rule**: "Building a network, not a directory. Trust first, connections second."
- **Environments**:
  - **Phone A (Presenter 1)**: Student app view (Android release build)
  - **Phone B / Laptop (Presenter 2)**: Alumnus Giver app view + Admin portal
- **Test Mode Policy**: All payments display: *"Test mode: no real money moves"*.

---

## 2. Real Volunteer Personas (No Invented Users)

| Persona | Role | Email | College / Affiliation | Purpose |
| :--- | :--- | :--- | :--- | :--- |
| **Aarav Sharma** | Student | `aarav.student@vips.edu` | VIPS-TC, BCA 2025 | Seeks resume feedback & frontend internship advice |
| **Priya Mehta** | Verified Alumna (Giver) | `priya.alumni@vips.edu` | VIPS-TC, BCA 2022 (Software Engineer at FinTech) | Top Rated giver, available online now |
| **Dr. Rajesh Sen** | Admin / Faculty | `admin@vips.edu` | VIPS-TC Placement & Alumni Cell | College admin dashboard & moderation |

---

## 3. Minute-by-Minute Pitch & Demo Script

```
[0:00 - 0:30]  The Hook: Directory Failure vs WarmPath Solution
[0:30 - 1:15]  Student Flow: Institutional Verification, DPDP Consent & AI Intent
[1:15 - 2:00]  The Engine: Same-College 100% Free Match & Transparent Heuristic
[2:00 - 2:45]  The Giver Flow: Capacity Limits & "Go Online Now" Live Countdown
[2:45 - 3:30]  Safety & Live Session: Masked Contacts, Scam Interception & Video Call
[3:30 - 4:00]  Ratings & Economics: Bayesian Smoothing, Band Progression & Admin Proof
```

### [0:00 - 0:30] The Hook: Network, Not a Directory
**Spoken by Presenter 1**:
> *"Distinguished jury: Traditional alumni networks fail because they are passive directories. A student searches LinkedIn or a college portal, sends 20 cold messages into the void, and gets zero replies. Givers get overwhelmed, spam proliferates, and scammers pose as recruiters offering fake internships for 'registration fees'.*  
> *WarmPath is different. We built an active, intent-first, rating-powered network. We don't browse a directory—we match intent, verify identity through university rosters, protect students with automated safety filters, and ensure 100% free alumni access within the college."*

---

### [0:30 - 1:15] Student Onboarding: Consent, Skills & Stated Intent
**Action on Phone A (Student)**:
1. Open WarmPath app. Show login screen. Enter `aarav.student@vips.edu`.
2. OTP is verified instantly against the **VIPS-TC institutional roster**.
3. Point out the **DPDP Act Consent Modal**: *"Explicit, unbundled consent before any document is analyzed."*
4. Upload PDF Resume. The screen displays extracted skills (React, TypeScript, Tailwind) with user editing enabled.
5. Tap the single intent prompt: *"What do you want next?"*  
   Select: **"Crack frontend developer interview at a fintech startup."**

**Spoken by Presenter 1**:
> *"Notice: Aarav didn't fill out a 50-field profile. He gave explicit consent under India's Digital Personal Data Protection Act, our Gemini pipeline extracted his skills, and he declared a single clear intent. No fake data, no public search indexing."*

---

### [0:15 - 2:00] The Heuristic Matcher: Same-College Free
**Action on Phone A**:
1. Tap **"Find Alumni Mentors"**.
2. Tap on **Priya Mehta's card** (Alumna, Software Engineer).
3. Tap **"Why this match?"** to reveal the 6-factor score explanation:
   - Expertise Fit: 35% (Frontend & React match)
   - Intent Fit: 25% (Fintech interview prep)
   - Affinity: 15% (Same college: VIPS-TC)
   - Availability: 10% (Has open capacity this week)
   - Rating: 10% (Top Rated band)
   - Response Odds: 5% (94% acceptance history)
4. Show the transparent pricing disclosure: **"Free: Own College Alumni"** (No credit required).

**Spoken by Presenter 1**:
> *"No opaque black box. WarmPath explains exactly why Priya is recommended. Because Priya and Aarav share the same alma mater, this session costs zero rupees and zero credits. No paywalls between alumni and their own juniors."*

---

### [2:00 - 2:45] Giver Availability: Capacity & "Go Online Now"
**Action on Phone B (Giver)**:
1. Switch to Priya's screen.
2. Show the **Weekly Capacity Stepper**: Set to `4 sessions/week` (2 used, 2 remaining). Givers are never overwhelmed.
3. Tap **"Go Online for 30 minutes"**.
4. A pulsing green indicator and live countdown timer `29:59` starts ticking.
5. Instantly, on Student Phone A, Priya's status switches to **"Online Now - Instant Connect Available"**!
6. Student taps **"Connect Now"** with pre-filled intent.

**Spoken by Presenter 2**:
> *"Alumni can't commit to endless calendar meetings. Priya taps 'Go online for 30 minutes' between meetings. Her status updates in real-time across the network. Aarav sees she is online right now and requests an instant connect."*

---

### [2:45 - 3:30] Safety & In-App Session
**Action on Phone B**:
1. Priya accepts the incoming request with one tap.
2. Open the in-app chat thread.
3. Student attempts to type a test message: *"Here is my WhatsApp number 9876543210 and send registration fee to..."*
4. **Safety Filter in action**:
   - The phone number is masked: `[Contact masked for safety]`.
   - An amber warning banner appears: `⚠️ Scam prevention alert: Never pay registration or test fees off-platform.`
5. Tap **"Join Video Call"**.
6. Show in-app secure video room via WebRTC/Jitsi. Point out the active call timer enforcing the 5-minute minimum completion threshold.

**Spoken by Presenter 2**:
> *"Notice what just happened. The student tried to share an off-platform phone number and mentioned a registration fee. WarmPath masked the phone number and flagged the recruitment scam keyword instantly. No off-platform harassment. The session takes place directly inside our encrypted call relay."*

---

### [3:30 - 4:00] Ratings, Bands & Economic Fairness
**Action on Phone A (Student)**:
1. Call completes. The student is presented with the **Rating Screen**:
   - Select 5 stars.
   - Tap feedback tags: *"Actionable feedback"*, *"Clear guidance"*.
   - Submit review.
2. Switch to Giver's **Band Dashboard** (`/me/band`):
   - Show rating: **4.85 Smoothed Average**.
   - Current Band: **Top Rated** (80% payout share).
   - Plain-language tier progression checklist and hysteresis protection.
3. Switch to Laptop (Admin Portal):
   - Show `admin.warmpath.org`: Active verification queue, safety audit log, and institution dashboard.

**Spoken by Presenter 1**:
> *"Giver compensation and prestige are driven by student ratings, not college tiering. We use a Bayesian smoothed average with a prior weight of 5, meaning a single rogue review cannot destroy a mentor's standing. With verified rosters, automated scam blocking, and 100% free campus connections, WarmPath transforms alumni directories into an active, trusted career network. Thank you!"*

---

## 4. Safety & Payment Features Showcase (Test Mode)

### Razorpay Test Mode Flow
- To demonstrate cross-college paid reach (e.g., reaching recruiters or external experts):
  1. Open Plans sheet: **Standard Plan (₹299 / 1 credit)**.
  2. Tap "Subscribe". Razorpay test modal opens.
  3. Prominently display banner: `Test mode: no real money moves`.
  4. Use Razorpay test card `4111 1111 1111 1111`, OTP `123456`.
  5. Session credit is held in escrow until completion and the 48-hour dispute window has passed.

### Safety Safeguards
- **In-App Masking**: Emails and phone numbers regex-replaced with `[Contact masked for safety]`.
- **Scam Keywords**: "registration fee", "security deposit", "crypto", "pay to interview" intercepted by `SafetyPort.scan_text`.
- **One-Tap Report & Block**: Direct escalation to admin moderation queue.

---

## 5. Rehearsal Checklist for Jury Questions

| Jury Question | Technical Architecture & Solution | Proof File / Screen |
| :--- | :--- | :--- |
| **"How do you stop fake alumni and recruitment scams?"** | Multi-tier identity verification. College emails checked against university enrollment rosters (`data/institutions.csv`, `approved_members.csv`). Recruiter verification requires company registration (CIN/GST). All messages scanned by `SafetyPort.scan_text` for upfront fee scams. | [`docs/TRUST_AND_SAFETY.md`](file:///c:/Users/Admin/OneDrive/Desktop/WarmPath/docs/TRUST_AND_SAFETY.md)<br/>Admin Portal `/admin/verification` |
| **"How do you prevent review bombing or reciprocal rating collusion?"** | Bayesian smoothed average: $\text{Score} = \frac{4.0 \times 5 + \sum r}{5 + n}$. Down-weighting algorithm flags reciprocal pairs between identical users (50% reduction) and sudden rating bursts. Hysteresis buffer (0.05) prevents band flip-flopping. Band changes require $\ge 5$ rated sessions. | [`backend/app/modules/ratings/service.py`](file:///c:/Users/Admin/OneDrive/Desktop/WarmPath/backend/app/modules/ratings/service.py)<br/>Giver `/ratings/band` |
| **"What if the giver doesn't show up after credits are paid?"** | Double-entry credit escrow. Credits are reserved on booking and only released to the giver after a verified call (minimum 5 minutes with both participants joined) PLUS a 48-hour dispute window. If the giver no-shows, 100% of the credit is refunded automatically and a penalty is recorded. | [`backend/app/modules/credits/service.py`](file:///c:/Users/Admin/OneDrive/Desktop/WarmPath/backend/app/modules/credits/service.py)<br/>Dispute Dialog `/sessions/{id}/dispute` |
| **"How does this scale to 50,000 students across 20 colleges?"** | Stateless FastAPI backend with asyncpg connection pooling. Vector searches use `pgvector` with IVFFlat / HNSW index partitions by college ID (sub-25ms latency). Redis TTL handles ephemeral presence without touching Postgres. Asynchronous outbox worker (ARQ) processes background events and notifications. | [`docs/PERFORMANCE.md`](file:///c:/Users/Admin/OneDrive/Desktop/WarmPath/docs/PERFORMANCE.md)<br/>[`backend/Dockerfile.prod`](file:///c:/Users/Admin/OneDrive/Desktop/WarmPath/backend/Dockerfile.prod) |
| **"How do you comply with India's DPDP Act on privacy?"** | Explicit, unbundled consent before resume parsing. No public web indexing or directory scraping. Extracted skills are fully editable/deletable by the student before vectorization. Built-in `GET /me/data-export` and `DELETE /me` endpoints for right-to-erasure compliance. | [`docs/TRUST_AND_SAFETY.md`](file:///c:/Users/Admin/OneDrive/Desktop/WarmPath/docs/TRUST_AND_SAFETY.md)<br/>Consent Dialog in Flutter App |

---

## 6. Backup & Disaster Recovery Plan

1. **Pre-Recorded 4K Video Fallback**:
   - Location: `docs/demo_backup_video.mp4` (or cloud mirror link).
   - If venue Wi-Fi fails, switch to the full-fidelity narrated screencast immediately.
2. **Dual-Device Offline Mirror**:
   - Both Android phones preloaded with the standalone release APK pointing to the local API via USB reverse tethering (`adb reverse tcp:8000 tcp:8000`).
3. **Emergency Data Reset (10-Second Reset)**:
   - If resetting between judging sessions, run:
     ```bash
     python scripts/deploy/reset_demo_data.py --force
     ```
   - This cleans transient requests and call sessions while leaving student/alumni logins intact.
