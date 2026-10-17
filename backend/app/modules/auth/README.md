# Auth & Verification Module

- **Owner**: M1 (Anmol Garg)
- **Status**: Implemented
- **Alembic Branch**: `auth` (migrations stored in `migrations/`)

## Responsibilities

1. **Passwordless Email OTP Authentication**:
   - `POST /auth/request-otp`: Validates institutional email affiliation against `institutions.email_domains`. Generates a cryptographically random 6-digit OTP using `secrets`, stores only its salted SHA-256 hash in Redis (10-minute TTL, max 5 attempts), applies Redis rate limiting (3/hr per email, 10/hr per IP), and delivers HTML email via SMTP (`aiosmtplib`). Never logs or returns the OTP code.
   - `POST /auth/verify-otp`: Validates OTP against stored hash. On success, creates user if first login. Issues access JWT (configured by `ACCESS_TOKEN_MINUTES`) and rotating refresh token (stored hashed with reuse-detection family revocation).
   - `POST /auth/refresh`: Rotates refresh token within family. Revokes entire family if token reuse is detected.
   - `POST /auth/logout`: Revokes active session and refresh token family.

2. **Layer 1 Identity & Approved-List Matching**:
   - Matches incoming emails against `approved_members` loaded from `data/approved_members.csv`.
   - On match, upgrades user from `email_only` to `verified` with designated role (`student`, `alumnus`, `faculty`) and awards corresponding badges (`Verified Student`, `Verified Alumnus`).
   - Automatically publishes `user.verified` event to the outbox.

3. **Verification Request Submissions**:
   - `POST /verification/submit`: Submits institutional credentials and documentation for `alumnus`, `employer`, `expert`, or `faculty` verification.
   - `GET /verification/status`: Returns current verification tier, active badges, and pending submissions.

4. **User Profile & DPDP Compliance**:
   - `GET /me`: Full profile with institutional relation and badges.
   - `PATCH /me`: Update display name, headline, avatar.
   - `DELETE /me`: DPDP-compliant personal data anonymization, token revocation, and account deactivation.
   - `GET /me/data-export`: Full personal data export in JSON format.
   - `GET /institutions`: Public directory of supported institutions and affiliated domains.

5. **Exported Dependencies**:
   - `get_current_user`: Injected in `app/core/deps.py`.
   - `require_role(*roles)`: Role-based authorization gate.
