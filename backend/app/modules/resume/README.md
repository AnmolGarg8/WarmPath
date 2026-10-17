# Module: resume

- **Owner**: M2
- **Responsibilities**: Resume upload, Gemini JSON parsing, consent handling, and student intent prompt.
- **Migrations Branch**: `resume` (stored in `migrations/`)

## Contract Endpoints
- `POST /resume`: Upload resume PDF for extraction
- `GET /resume/profile`: Retrieve parsed resume skills and entities
- `PUT /resume/profile`: Update or correct parsed resume entities
- `DELETE /resume`: Delete uploaded resume and extracted vectors
- `PUT /me/intent`: Save 'what do you want next' intent prompt
- `GET /me/intent`: Retrieve current student intent prompt
- `GET /me/consents`: Retrieve DPDP consent records
- `PUT /me/consents`: Update DPDP consent preferences
