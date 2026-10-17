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

## 5. Backup & Disaster Recovery Plan
If unforeseen venue issues occur (e.g. venue firewall blocks WebSockets or Mailpit port):
1. **Pre-recorded Screen Captures**: High-definition video recordings of all 7 demo steps captured during rehearsals are stored in `docs/assets/demo_backup_video.mp4` as an immediate walkthrough fallback.
2. **Secondary Hardware**: A secondary physical Android device with the debug APK pre-installed (`app/build/app/outputs/flutter-apk/app-debug.apk`).
3. **Local Hotspot**: Cellular hotspot prepared in case venue Wi-Fi blocks WebRTC ports used by Jitsi Meet.
