# Module: auth

- **Owner**: M1
- **Responsibilities**: Authentication, OTP verification, user profiles, data export, and institution lookups.
- **Migrations Branch**: `auth` (stored in `migrations/`)

## Contract Endpoints
- `POST /auth/request-otp`: Request one-time password for email
- `POST /auth/verify-otp`: Verify one-time password and receive tokens
- `POST /auth/refresh`: Refresh access token
- `POST /auth/logout`: Revoke active session token
- `GET /me`: Retrieve current authenticated user profile
- `PATCH /me`: Update authenticated user profile
- `DELETE /me`: Request account and data deletion under DPDP Act
- `GET /me/data-export`: Download personal data export
- `GET /institutions`: List supported institutions
- `POST /verification/submit`: Submit institutional credentials for verification
- `GET /verification/status`: Check current verification status
