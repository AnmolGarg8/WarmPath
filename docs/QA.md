# WarmPath Manual Quality Assurance (QA) Checklist

This document is the manual verification test suite covering every must-have and should-have capability in the WarmPath specification. Any teammate or external reviewer can verify the entire product in **30 minutes**.

---

## Verification Test Matrix

| ID | Feature Area | Preconditions | Action / Test Input | Expected Result | Status |
| :--- | :--- | :--- | :--- | :--- | :---: |
| **AUTH-01** | College Domain Match | Backend running | Enter email `student@vips.edu` | System recognizes VIPS-TC institutional domain; OTP sent to Mailpit/SMTP. | [x] PASS |
| **AUTH-02** | OTP Verification & Token | OTP received | Enter 6-digit OTP code | Returns access & refresh JWT tokens with assigned trust level (`Verified`). | [x] PASS |
| **RES-01** | DPDP Consent Gate | Logged in as student | Navigate to resume upload | Consent modal displays explicit data usage terms; upload disabled until checked. | [x] PASS |
| **RES-02** | Resume Skill Extraction | Consent accepted | Upload sample engineering PDF resume | Gemini API parses structured skills, projects, and education into editable form. | [x] PASS |
| **RES-03** | Intent Declaration | Skills confirmed | Enter intent: "Crack frontend fintech role" | Profile vector generated and stored in `pgvector` under user account. | [x] PASS |
| **DISC-01**| Same-College Free Match | Student from VIPS-TC | Navigate to Discover page | Recommends verified VIPS-TC alumni with "100% Free: Own College" badge. | [x] PASS |
| **DISC-02**| Heuristic Score Breakdown | Recommendations shown | Tap "Why this match?" | Explains match score: 35% Expertise, 25% Intent, 15% Affinity, 10% Availability. | [x] PASS |
| **AVAIL-01**| Giver Capacity Stepper | Logged in as Giver | Adjust capacity to 5 sessions/week | Saved via `PUT /me/availability`; capacity usage counter updates correctly. | [x] PASS |
| **AVAIL-02**| Weekly Recurring Windows | Availability tab | Add Monday 18:00 - 20:00 window | Windows validate without overlaps and persist in database. | [x] PASS |
| **AVAIL-03**| "Go Online" Live Timer | Giver dashboard | Tap "Go online for 30 minutes" | Redis key set with 30m TTL; live countdown timer ticks down; stop button works. | [x] PASS |
| **SESS-01**| Instant Connect Request | Giver is online now | Student taps "Instant Connect" | Request created (`kind: instant`); giver receives real-time notification. | [x] PASS |
| **SESS-02**| Slot Picker Booking | Giver offline | Student taps "Book a Slot" | Shows available slots inside giver's windows within plan booking horizon. | [x] PASS |
| **CHAT-01**| Contact Info Masking | Request accepted | Student sends phone `9876543210` or email | Chat displays `[Contact masked for safety]`; raw contact never leaked. | [x] PASS |
| **SAFE-01**| Scam Keyword Detection | Chat open | Type "pay registration fee on Telegram" | Safety filter flags scam trigger; displays amber warning banner. | [x] PASS |
| **SAFE-02**| One-Tap Report / Block | Chat or profile | Tap Report -> "Inappropriate behavior" | Event `report.filed` sent; ticket appears in Admin Moderation Queue. | [x] PASS |
| **CALL-01**| Video Call Join Tracking | Session time reached | Tap "Join Call" | WebRTC / Jitsi view opens; `POST /sessions/{id}/join` timestamp recorded. | [x] PASS |
| **CALL-02**| 5-Minute Call Threshold | In call | Leave call before 5 minutes | Session status marked incomplete; no payout triggered until 5m minimum reached. | [x] PASS |
| **RATE-01**| 5-Star Rating Submission | Session completed | Student rates 5 stars with feedback tags | Recorded via `POST /sessions/{id}/rating`; event `rating.submitted` published. | [x] PASS |
| **RATE-02**| Bayesian Smoothed Average | Rating submitted | Fetch `/me/band` for giver | Formula computes Bayesian average using prior mean 4.0 and weight 5. | [x] PASS |
| **RATE-03**| Band Progression & Hysteresis | 5+ sessions, avg >= 4.2 | Complete 5th high-rated session | Giver transitions from `Rising` to `Trusted` (70% share); hysteresis prevents flip-flop. | [x] PASS |
| **PAY-01** | Razorpay Test Payment | Cross-college booking | Purchase Standard Plan (₹299) | Opens Razorpay test modal with "Test mode: no real money moves" badge; succeeds. | [x] PASS |
| **ADM-01** | Admin Verification Queue | Admin logged in | Open `/admin/verification` | Displays pending member rosters and recruiter verifications for approval. | [x] PASS |
| **ADM-02** | Admin Moderation Action | Reported chat item | Resolve report with "Dismiss" or "Restrict" | Offending user trust level adjusted; action recorded in audit log. | [x] PASS |

---

## End-to-End Verification Sign-Off

- **Date of Verification**: October 17, 2026
- **Test Environment**: Managed Docker Container (`backend/Dockerfile.prod`), PostgreSQL 16 + pgvector, Redis 7-alpine, Flutter Mobile APK (release build).
- **Execution Lead**: Member 3 (M3) - Availability, Sessions, Ratings & Deployment
- **Result**: 23 / 23 Tests Passed (100% Core Requirements Verified).
- **Acceptance Criteria Met**:
  - A stranger can deploy everything from [`docs/DEPLOY.md`](file:///c:/Users/Admin/OneDrive/Desktop/WarmPath/docs/DEPLOY.md).
  - The release APK installs and connects against the production API.
  - The 4-minute demo script runs end-to-end within time.
