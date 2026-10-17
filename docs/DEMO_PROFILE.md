# WarmPath Demo Profile Reference

## 1. Overview
In a production deployment, WarmPath enforces strict trust and dispute windows:
- 48 hours for students to dispute low-effort or abusive sessions.
- 72 hours for givers to respond to incoming mentorship requests before credits auto-refund.
- 5 minutes minimum dual-party presence for a call session to count as completed.
- 5 and 10 rated sessions required before reaching the Trusted and Top Rated bands.

Because a live product presentation or jury demonstration takes only 4 to 5 minutes, waiting 48 hours or 72 hours is impossible. Rather than relying on fake data or mock state, WarmPath implements an **Honest Demo Profile**:
- Real backend execution, real database records, real WebSocket state, and real asynchronous workers.
- Shortened configuration timers that allow live demonstration of expiry, dispute windows, and band movements.
- **Mandatory, persistent labelling**: Whenever shortened timers or test payment gateways are active, both the Flutter mobile application and React admin panel display visible banners explaining that the demo profile is active.

---

## 2. Configuration Settings: Production vs. Demo Profile

| Setting Name | Production Default | Demo Profile Value | Unit | Purpose & Rationale | Status in Monorepo |
|---|---|---|---|---|---|
| `DEMO_PROFILE` | `false` | `true` | boolean | Master flag enabling demo banners and public visibility | Added to `Settings` |
| `TEST_MODE` | `true` | `true` | boolean | Payment test mode flag (e.g. Razorpay test sandbox) | Existed |
| `DISPUTE_WINDOW_MINUTES` | `2880` (48 hours) | `2` | minutes | Dispute window after session completion before giver payout | Added to `Settings` (complements `DISPUTE_WINDOW_HOURS`) |
| `NO_REPLY_EXPIRY_MINUTES` | `4320` (72 hours) | `5` | minutes | Inactivity expiry before mentorship request auto-declines & refunds credit | Added to `Settings` (complements `AUTO_REFUND_HOURS`) |
| `MIN_CALL_SECONDS` | `300` (5 minutes) | `60` | seconds | Minimum call duration with both parties connected for session completion | Added to `Settings` (complements `MIN_CALL_DURATION_MINUTES`) |
| `SCHEDULER_INTERVAL_SECONDS` | `60` | `15` | seconds | Arq periodic worker poll interval for checking session expirations | Added to `Settings` |
| `TRUSTED_MIN_SESSIONS` | `5` | `1` | sessions | Minimum rated sessions required before qualifying for Trusted band | Existed in `Settings` |
| `TOP_RATED_MIN_SESSIONS` | `10` | `2` | sessions | Minimum rated sessions required before qualifying for Top Rated band | Existed in `Settings` |

---

## 3. Public Configuration Endpoint
- **Path**: `GET /config/public`
- **Owner**: `backend/app/modules/auth/`
- **Security**: No secrets or private keys exposed.
- **Contract Schema**:
  ```json
  {
    "demo_profile": true,
    "test_mode": true,
    "windows": {
      "dispute_minutes": 2,
      "no_reply_minutes": 5,
      "min_call_seconds": 60
    },
    "band_thresholds": {
      "trusted_min_sessions": 1,
      "top_rated_min_sessions": 2,
      "lowered": true
    }
  }
  ```

---

## 4. UI Banner Rules

### Flutter Mobile App
1. **Demo Banner**: When `demo_profile == true`, a persistent banner is displayed across primary flows:
   > **Demo profile: timers are shortened for the demo**
2. **Test Mode Banner**: When `test_mode == true`, payment and subscription views display:
   > **Test mode: no real money moves**
3. **Lowered Threshold Notice**: When `band_thresholds.lowered == true` or `demo_profile == true`, the rating band section states:
   > *Rating band thresholds are shortened for demo verification (Trusted: 1 session, Top Rated: 2 sessions).*

### Admin Panel
When `demo_profile == true`, a persistent banner is rendered at the top of the admin layout:
> **Demo profile: timers are shortened for the demo**

---

## 5. Activating the Demo Profile
1. Copy the example demo environment file:
   ```bash
   cp backend/.env.demo.example backend/.env
   ```
2. Start the services:
   ```bash
   cd backend && docker compose up -d
   ```
3. Verify public configuration:
   ```bash
   curl http://localhost:8000/config/public
   ```
4. To return to the standard production profile:
   Set `DEMO_PROFILE=false` or remove the override keys from `backend/.env`.
