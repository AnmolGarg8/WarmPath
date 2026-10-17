# Module: matching

- **Owner**: M2
- **Responsibilities**: Heuristic match scoring, recommendation feed, and giver profile discovery.
- **Migrations Branch**: `matching` (stored in `migrations/`)

## Contract Endpoints
- `GET /recommendations`: Get ranked mentor recommendations for student
- `GET /givers/{id}`: View giver mentorship profile
- `PUT /me/giver-profile`: Update own giver mentorship profile and topics
- `GET /me/giver-profile`: Retrieve own giver mentorship profile
