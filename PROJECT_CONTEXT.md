# WarmPath: project context (read this fully before any task)

## 1. Product
WarmPath is a trusted, intent-first, rating-powered alumni network for the hackathon theme "Alumni Network and Professional Connections: Building a Network, Not a Directory". Team Unsolved Loop (VIPS-TC). Working name; may change.
Core flow: a student joins with a college email and is checked against an institution-approved list, uploads a resume (with consent), WarmPath extracts skills, the student states intent ("what do you want next?"), and the platform recommends the best-fit verified alumni of the SAME college for free. Students on a paid plan can also reach givers from other colleges and recruiters, founders, faculty and experts. Those givers earn for their time; their pay share depends on student RATINGS, never on college prestige (no Tier 1/2/3 labels anywhere). Givers set weekly capacity and online windows; nothing is routed outside them. Students see who is online now and can connect instantly, or book a slot (booking rules depend on plan). Every completed session ends with a rating. Everyone is verified, payments are protected until the session completes, and scams are detected. Everyone earns and spends credits in one credit economy.
Positioning: trust first, networking second. Network, not directory: we recommend, connect, schedule and measure.

## 2. Roles
student, alumnus, recruiter, founder, faculty, expert, institution_admin, moderator, platform_admin. A user can hold several roles (an alumnus can also seek help). Any verified user can seek; givers need giver verification.

## 3. Ownership (one owner per folder; do not edit another member's folders)
M1: backend/app/core, modules auth and trust; app/lib/core, features auth and safety; admin/src/core, pages moderation and verification; scripts/, .github/, root files, PROJECT_CONTEXT.md.
M2: backend modules resume and matching; app features onboarding and discover.
M3: backend modules availability, sessions, ratings; app features availability, sessions, ratings.
M4: backend modules credits, payments, institution; app feature plans_wallet; admin pages dashboard and seats.
Each module owns its migrations (app/modules/<name>/migrations, Alembic branch label = module name) and its contract fragment contracts/modules/<name>.yaml. Dependency files, app/main.py, app/lib/app_router.dart and admin routing are frozen after P0; ask M1 through a GitHub issue if a change is truly needed.

## 4. Engineering rules (non-negotiable)
- Build complete, backend-wired features. No frontend-only screens, no mock or demo data, no hard-coded sample users, no silent fallback to fake data. If an external service fails, return a typed error and show an error state with Retry.
- The only seeded data is real reference data from CSV files the team supplies (institutions, approved members).
- Never commit secrets. Use .env files; commit only .env.example.
- Modules talk to each other ONLY through ports (synchronous, app/core/ports.py) and events (asynchronous, outbox). Never import another module's models or services.
- Fail closed on safety: if a port is not ready, deny and return port_not_ready.
- Every list endpoint is cursor-paginated. Every write that can be retried accepts an Idempotency-Key. Rate limits depend on trust level.
- Tests for all pure logic and for every endpoint (real Postgres and Redis). Do not mark work done unless tests ran and passed.
- Only edit files inside your owned folders. Use small commits with `type(scope): summary`. Never force-push main. Check `git status` before every commit.
- Payments run in Razorpay TEST MODE only. The UI and docs must state "Test mode: no real money moves".
- Branding is WarmPath only (team Unsolved Loop). No other company branding.

## 5. Design tokens
Font Inter. Colours: indigo 16163A (text, dark), deep indigo 2B2D6E, coral FF6B4A (primary action), teal 0FB5A5, success green 15803D, amber F5A524, slate 64748B, surface EEF1F8, white FFFFFF. Rounded 12-16px cards. Rating bands: Rising (slate), Trusted (teal), Top Rated (amber with star). Never convey status by colour alone: colour plus icon plus label. Currency in INR with the rupee sign.

## 6. Domain rules, defaults (all configurable by env), events and ports
Rating bands for givers: Rising (default), Trusted (smoothed average >= 4.2 and >= 5 rated sessions), Top Rated (smoothed average >= 4.6, >= 10 rated sessions, completion rate >= 90%). Smoothed average = (prior_mean*prior_weight + sum_of_ratings) / (prior_weight + n) with prior_mean 4.0 and prior_weight 5. Band changes only after at least 5 rated sessions. Payout share of the credit value: Rising 60%, Trusted 70%, Top Rated 80%.
Plans (illustrative, config-driven; INR per month): Campus free (own-college only); Standard 299 with 1 credit; High 499 with 2 credits; Premium 899 with 4 credits. Credit value in rupees = plan price / credits at purchase, stored in the ledger. One cross-college session = 1 credit, 20 minutes. Reach: Standard reaches Rising givers; High reaches Rising and Trusted; Premium reaches all bands including recruiters, founders, faculty and experts. Booking horizon: Standard 3 days, High 14 days, Premium 30 days. Request priority in a giver's inbox: Premium 3, High 2, Standard 1. Own-college sessions cost the student nothing; the giver earns 1 non-cash affinity credit (spendable, not cash-out-able). Paid credits earned by givers can be cashed out (test mode) or spent or donated to the scholarship pool.
Session rules: minimum call duration for completion 5 minutes with both sides joined; dispute window 48 hours; no reply within 72 hours returns the credit automatically; giver no-show returns the credit and counts against the giver; student no-show consumes the credit. Payout to the giver is released only after completion and the dispute window.
Trust levels: new, verified, established, restricted (private, never shown as a ranking; never uses college prestige). Daily request limits: new 3, verified 10, established 25, restricted 1 with messages reviewed first.
Matching score v1 (heuristic, label it honestly): 35% expertise fit, 25% intent fit, 15% affinity, 10% availability, 10% rating, 5% response odds; HARD gates for capacity and safety (verified and not restricted).
Events (outbox topics, payloads carry ids): user.verified, trust.level_changed, resume.parsed, profile.updated, giver.profile_updated, request.created, request.accepted, request.declined, session.booked, session.started, session.completed, session.no_show, rating.submitted, band.changed, credits.reserved, credits.released, credits.refunded, payment.captured, subscription.activated, subscription.cancelled, report.filed, dispute.opened, dispute.resolved.
Ports (fail closed): SafetyPort.scan_text(text, sender_id, context) -> {flags, action: allow|warn|block|review}; TrustPort.get_level(user_id), can(user_id, action) -> {allowed, reason} and is_blocked(user_a, user_b) -> bool; CreditsPort.can_access(student_id, giver_id) -> {allowed, reason, plan, cost}, reserve(student_id, request_id, giver_id), release(request_id), refund(request_id, reason); RatingsPort.get_band(giver_id) -> {band, smoothed_avg, n, completion_rate}; PresencePort.status(user_ids) -> {online, capacity_left}; MatchingPort.explain(student_id, giver_id) -> why-lines.

## 7. API contract v1 (paths fixed; owner module in brackets). Errors: {"error":{"code","message","details"}}. Lists: {items,next_cursor}. Times ISO-8601 with offset.
[auth] POST /auth/request-otp, POST /auth/verify-otp, POST /auth/refresh, POST /auth/logout, GET /me, PATCH /me, DELETE /me, GET /me/data-export, GET /institutions, POST /verification/submit, GET /verification/status
[trust] POST /reports, POST /blocks, DELETE /blocks/{user_id}, GET /me/trust, GET /admin/moderation/queue, POST /admin/moderation/{id}/resolve, GET /admin/verification/queue, POST /admin/verification/{id}/decide, POST /admin/approved-members/upload, GET /admin/audit-log
[resume] POST /resume, GET /resume/profile, PUT /resume/profile, DELETE /resume, PUT /me/intent, GET /me/intent, GET /me/consents, PUT /me/consents
[matching] GET /recommendations, GET /givers/{id}, PUT /me/giver-profile, GET /me/giver-profile
[availability] PUT /me/availability, GET /me/availability, POST /me/online, DELETE /me/online, GET /presence, WS /ws
[sessions] POST /requests, GET /requests, GET /requests/{id}, POST /requests/{id}/accept, POST /requests/{id}/decline, GET /givers/{id}/slots, POST /requests/{id}/messages, GET /requests/{id}/messages, POST /sessions/{id}/join, POST /sessions/{id}/leave, GET /sessions/{id}, GET /me/sessions, POST /notifications/devices
[ratings] POST /sessions/{id}/rating, POST /sessions/{id}/request-quality, POST /sessions/{id}/dispute, GET /givers/{id}/rating-summary, GET /me/band, GET /admin/disputes, POST /admin/disputes/{id}/resolve
[credits] GET /plans, GET /me/subscription, GET /me/wallet, GET /me/earnings, POST /me/cashout, POST /me/donate-credits, GET /sponsored-seats, POST /admin/sponsored-seats
[payments] POST /subscriptions, POST /subscriptions/cancel, POST /webhooks/razorpay
[institution] GET /admin/dashboard/overview, GET /admin/dashboard/skill-gap, GET /admin/dashboard/safety-summary, GET /admin/dashboard/seats

## 8. Repo facts
Backend: FastAPI modular monolith, stateless, Postgres with pgvector, Redis, arq worker. App: Flutter, Android emulator emulator-5554. Admin: React. Local URLs: API http://localhost:8000 (Android emulator http://10.0.2.2:8000), Mailpit http://localhost:8025.

## 9. Environment variables
DATABASE_URL, REDIS_URL, JWT_SECRET, ACCESS_TOKEN_MINUTES, REFRESH_TOKEN_DAYS, SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASSWORD, SMTP_FROM, GEMINI_API_KEY, GEMINI_TEXT_MODEL, GEMINI_EMBED_MODEL, RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET, RAZORPAY_WEBHOOK_SECRET, FCM_SERVICE_ACCOUNT_PATH, JITSI_BASE_URL (default https://meet.jit.si), plus every default in section 6 as upper-case settings.
