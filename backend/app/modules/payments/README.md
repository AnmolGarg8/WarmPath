# Module: payments

- **Owner**: Member 4 (M4)
- **Status**: Complete & Verified (Test Mode)
- **Branch**: `m4/b2-razorpay-test-mode`
- **Migrations Branch**: `payments` (stored in `migrations/`)

---

## 1. Overview & Architecture

The `payments` module manages outbound and inbound payment flows for WarmPath in **Razorpay TEST MODE**. It provides:
1. **Razorpay Subscriptions**: Test-mode checkout order generation for paid student tiers (`standard`, `high`, `premium`).
2. **Signed Webhook Ingestion**: Cryptographic verification of inbound webhook signatures using HMAC-SHA256, strictly rejecting untrusted or tampered payloads.
3. **Replay Idempotency**: Recording of every incoming webhook event in `payment_events(event_id)` to ensure replayed webhooks are acknowledged without duplicate processing or double-crediting.
4. **Decoupled Event Publishing**: Emitting transactional outbox events (`payment.captured`, `subscription.activated`, `subscription.cancelled`, `payout.disbursed`) consumed asynchronously by the credits and ledger modules.
5. **Cash-out Simulation**: Test-mode giver payout requests and admin approval, backed by an event-fed read model `giver_earnings_read_model` without direct runtime dependencies on the credits ledger.
6. **Nightly Subscription Reconciliation**: Comparing Razorpay remote subscription states against local database records to detect and reconcile lifecycle drift.

---

## 2. Test-Mode Client & Security Guard

The payments module utilizes the official Razorpay SDK wrapped in `RazorpayClientWrapper` (`backend/app/modules/payments/client.py`).

### Environment Configuration Guard
To guarantee live financial credentials are never accidentally used during development, testing, or staging:
- When `ENVIRONMENT != "production"`, `RazorpayClientWrapper` enforces that `RAZORPAY_KEY_ID` begins with `rzp_test_`.
- If a production key (`rzp_live_...`) is detected in a non-production environment, initialization immediately aborts with an `AppError(invalid_razorpay_keys, 500)`.
- All user-facing and admin responses explicitly include `"test_mode": true`.

### HTTP Resilience
- Outgoing HTTP calls use configured connection timeouts and an HTTP adapter with exponential backoff retries for transient gateway failures (HTTP 429, 500, 502, 503, 504).
- Retries are strictly restricted to idempotent read methods (`GET`, `HEAD`, `OPTIONS`) to prevent duplicate write requests.

---

## 3. Endpoints & Workflows

### Subscriptions

#### `POST /subscriptions`
- **Headers**: `Idempotency-Key` (required; rejects requests lacking this header with HTTP 400).
- **Body**: `{"plan_code": "standard" | "high" | "premium"}`
- **Behavior**:
  1. Validates the calling user is an authorized student/alumni and has not been restricted by Trust & Safety.
  2. Ensures the plan mapping exists in `razorpay_plan_mappings` (auto-synced via `ensure_razorpay_plans.py`).
  3. Creates a test-mode Razorpay subscription with total billing cycles.
  4. Stores the record in `subscriptions` table with status `"created"`.
  5. Caches the response in `idempotency_keys` so network retries return identical checkout parameters.
- **Response**: `{ "subscription_id": "...", "order_id": "...", "key_id": "rzp_test_...", "amount": 29900, "currency": "INR", "test_mode": true }`

#### `POST /subscriptions/cancel`
- **Body**: `{"at_period_end": true}`
- **Behavior**:
  - Updates active subscription to `"cancelling"` (if `at_period_end=True`) or `"cancelled"` (if immediate).
  - Calls Razorpay API to schedule cycle-end cancellation.
  - If immediate, immediately publishes `subscription.cancelled` outbox event.

---

### Webhook Verification & Lifecycle

#### `POST /webhooks/razorpay`
- **Headers**: `X-Razorpay-Signature` (HMAC-SHA256 signature).
- **Body**: Raw JSON payload from Razorpay.
- **Workflow**:
  1. **HMAC Signature Check**: Computes `hmac.new(RAZORPAY_WEBHOOK_SECRET, raw_body, hashlib.sha256).hexdigest()` and verifies in constant time against `X-Razorpay-Signature`. Non-matching signatures return HTTP 400 immediately.
  2. **Replay Deduplication**: Checks `payment_events` table for `event_id`. If already recorded, returns `{"status": "already_processed", "test_mode": true}` without re-triggering side effects.
  3. **Event Routing**:
     - `subscription.authenticated`, `subscription.activated`, `subscription.charged`: Sets subscription status to `"active"`, updates period timestamps, and publishes `payment.captured` and `subscription.activated`.
     - `subscription.cancelled`, `subscription.halted`: Sets status to `"cancelled"` and publishes `subscription.cancelled`.
     - `payment.failed`: Sets status to `"past_due"`.

---

### Cash-Out Simulation (Test Mode)

#### `POST /me/cashout` and `POST /payouts/request`
- **Body**: `{"amount_inr": 500.0, "upi_id": "alumni@upi"}`
- **Behavior**:
  1. Verifies the giver's trust level (restricted or new unverified users cannot cash out).
  2. Checks available earnings in `giver_earnings_read_model` (populated via events, completely avoiding direct database couplings with `credits`).
  3. If sufficient, deducts from the available earnings read model and stores a `PayoutRequest` in `payments_payout_requests` with status `"requested"`.
  4. Returns test-mode confirmation stating no real money has moved.

#### `POST /admin/payouts/{id}/approve`
- **Behavior**:
  1. Simulates payout settlement by marking `PayoutRequest.status = "paid"`.
  2. Publishes `payout.disbursed` outbox event so the credits module records the corresponding ledger entry.

---

## 4. Production Launch: Regulatory & Payout Partner Compliance

In prototype and test mode, all payments and payouts are simulated using Razorpay test mode. **Before launching real-money payouts in India, the following legal, tax, and compliance requirements MUST be fulfilled by a licensed payout partner (e.g., RazorpayX, Cashfree Payouts) and platform accounting.**

### 4.1 KYC (Know Your Customer) & Identity Verification
- **RBI Payout Guidelines**: Under RBI Master Directions for Payment Aggregators and Payouts, no disbursements can be made to unverified recipients.
- **Beneficiary Verification**:
  1. **PAN Validation**: Giver's Permanent Account Number (PAN) must be verified via NSDL/Protean API.
  2. **Bank Account Verification (Penny Drop)**: 1 INR penny drop via IMPS to verify beneficiary name match against the PAN card.
  3. **UPI VPA Validation**: Real-time UPI handle verification via NPCI directory to confirm account holder name before routing payouts.

### 4.2 TDS (Tax Deducted at Source) Compliance
Under the Indian Income Tax Act, 1961:
1. **Section 194J (Fees for Professional or Technical Services)**:
   - Mentorship and consulting payments to alumni/experts exceed threshold limits (INR 30,000 per financial year).
   - Platform must deduct 10% TDS (or 2% for purely technical services where applicable) from gross earnings prior to payout.
2. **Section 194M / Section 194C**:
   - For individual payers or contractual payouts where 194J does not apply, 5% TDS under 194M or 1%/2% under 194C applies once annual thresholds are met.
3. **Section 206AA & 206AB (Higher TDS for Non-PAN / Non-Filers)**:
   - If a giver has not provided a valid PAN, the platform is legally obligated to deduct TDS at the punitive rate of **20%**.
4. **TDS Certificates & Filing**:
   - Quarterly filing of Form 26Q and generation of Form 16A certificates for all givers receiving payouts.

### 4.3 GST (Goods & Services Tax) Compliance
1. **Platform Commission & Service Categorization**:
   - Platform platform share is classified under SAC 9983 (Other professional, technical and business services) or SAC 9992 (Education support services), attracting 18% GST.
2. **Invoicing Requirements**:
   - E-invoicing and tax invoice generation for every subscription purchase and platform commission fee.
3. **TCS under GST (Section 52 CGST Act)**:
   - As an Electronic Commerce Operator (ECO), the platform may be liable to deduct 1% TCS (0.5% CGST + 0.5% SGST or 1% IGST) on net value of taxable supplies made through the platform by registered service providers.

### 4.4 Licensed Partner Integration Architecture
For production:
- Integrate a licensed RBI-authorized **Payment Aggregator (PA)** for checkout (e.g., Razorpay Live, Stripe India, PayU).
- Integrate an authorized **Payout Gateway / Connected Banking Partner** (e.g., RazorpayX, Cashfree, ICICI Corporate Banking API) to process automated NEFT/RTGS/IMPS/UPI disbursements with built-in nodal account compliance.
