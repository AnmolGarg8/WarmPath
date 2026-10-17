# Module: credits

- **Owner**: M4
- **Responsibilities**: Credit ledger, subscription plans, cashouts, and student scholarship pool.
- **Migrations Branch**: `credits` (stored in `migrations/`)

## Contract Endpoints
- `GET /plans`: List subscription plans and credit allowances
- `GET /me/subscription`: Get authenticated user active subscription
- `GET /me/wallet`: Get credit balance and transaction history
- `GET /me/earnings`: Get earned credits and cashout availability
- `POST /me/cashout`: Request cashout for earned session credits
- `POST /me/donate-credits`: Donate earned credits to scholarship pool
- `GET /sponsored-seats`: Check sponsored seat availability
- `POST /admin/sponsored-seats`: Allocate sponsored seats for institution
