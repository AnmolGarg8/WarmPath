# Module: ratings

- **Owner**: M3
- **Responsibilities**: Post-session two-way ratings, smoothed averages, rating bands, and dispute flow.
- **Migrations Branch**: `ratings` (stored in `migrations/`)

## Contract Endpoints
- `POST /sessions/{id}/rating`: Student rates session quality (1-5 + feedback)
- `POST /sessions/{id}/request-quality`: Giver rates student preparation and request clarity
- `POST /sessions/{id}/dispute`: Open dispute for abusive or low-effort session
- `GET /givers/{id}/rating-summary`: Get public rating aggregate for giver
- `GET /me/band`: Get current rating band (Rising, Trusted, Top Rated)
- `GET /admin/disputes`: List pending session disputes
- `POST /admin/disputes/{id}/resolve`: Resolve a session dispute
