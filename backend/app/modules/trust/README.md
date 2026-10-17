# Module: trust

- **Owner**: M1
- **Responsibilities**: 7-layer trust engine, moderation queues, reporting, blocking, and audit logs.
- **Migrations Branch**: `trust` (stored in `migrations/`)

## Contract Endpoints
- `POST /reports`: Submit a report against a user, message, or session
- `POST /blocks`: Block a user from contacting or booking
- `DELETE /blocks/{user_id}`: Unblock a previously blocked user
- `GET /me/trust`: Retrieve current private trust score and safety limits
- `GET /admin/moderation/queue`: List pending moderation reports
- `POST /admin/moderation/{id}/resolve`: Resolve a moderation report
- `GET /admin/verification/queue`: List pending verification submissions
- `POST /admin/verification/{id}/decide`: Approve or reject a verification request
- `POST /admin/approved-members/upload`: Upload institutional roster CSV
- `GET /admin/audit-log`: Retrieve security audit trail
