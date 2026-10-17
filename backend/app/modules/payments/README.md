# Module: payments

- **Owner**: M4
- **Responsibilities**: Razorpay test mode subscriptions, payment webhooks, and payout release.
- **Migrations Branch**: `payments` (stored in `migrations/`)

## Contract Endpoints
- `POST /subscriptions`: Create checkout subscription in Razorpay test mode
- `POST /subscriptions/cancel`: Cancel current active subscription
- `POST /webhooks/razorpay`: Handle Razorpay payment and refund webhooks
