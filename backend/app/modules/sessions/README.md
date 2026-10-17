# Module: sessions

- **Owner**: M3
- **Responsibilities**: Mentorship request lifecycle, booking slots, in-app messaging, and call session rooms.
- **Migrations Branch**: `sessions` (stored in `migrations/`)

## Contract Endpoints
- `POST /requests`: Submit mentorship request to a giver
- `GET /requests`: List incoming or outgoing mentorship requests
- `GET /requests/{id}`: Get request details and agenda
- `POST /requests/{id}/accept`: Accept a mentorship request
- `POST /requests/{id}/decline`: Decline a mentorship request
- `GET /givers/{id}/slots`: List open booking slots for a giver
- `POST /requests/{id}/messages`: Send message in request thread
- `GET /requests/{id}/messages`: Get messages for a request thread
- `POST /sessions/{id}/join`: Join in-app video/voice call session
- `POST /sessions/{id}/leave`: Leave video/voice call session
- `GET /sessions/{id}`: Get session details and duration
- `GET /me/sessions`: List past and upcoming sessions
- `POST /notifications/devices`: Register device token for push notifications
