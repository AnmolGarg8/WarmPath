# Module: institution

- **Owner**: M4
- **Responsibilities**: College administrator web panel, skill-gap analysis, and network health metrics.
- **Migrations Branch**: `institution` (stored in `migrations/`)

## Contract Endpoints
- `GET /admin/dashboard/overview`: Overview of active sessions, response times, and fulfillment
- `GET /admin/dashboard/skill-gap`: Analysis of in-demand student skills vs alumni supply
- `GET /admin/dashboard/safety-summary`: Safety incident summary and moderation resolution rate
- `GET /admin/dashboard/seats`: Usage metrics for sponsored seats and credits
