# Module: availability

- **Owner**: M3
- **Responsibilities**: Giver availability schedules, weekly capacity caps, online presence, and real-time status.
- **Migrations Branch**: `availability` (stored in `migrations/`)

## Contract Endpoints
- `PUT /me/availability`: Set weekly schedule and session capacity limit
- `GET /me/availability`: Retrieve current availability schedule
- `POST /me/online`: Open 30-minute instant connect window
- `DELETE /me/online`: Close instant connect window
- `GET /presence`: Check online and capacity status for givers
- `WS /ws`: WebSocket connection for live presence updates
