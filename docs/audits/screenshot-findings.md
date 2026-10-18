# Audit Report: Screenshot Findings & Authentication Verification

- **Branch**: `m1/fx0-screenshot-audit`
- **Date**: 2026-10-18T05:15:00+05:30
- **Auditor**: M1 (Platform & Quality Owner)
- **Status**: Audit Completed — Action Items Filed for Owners (M1, M2, M3, M4)

---

## 1. Executive Summary

An audit of running application screens revealed several items of content that appear fabricated or inconsistent with real backend state. 

Investigation of source code, database tables, and network endpoints demonstrates:
1. **Source Origin**: **100% of the fabricated content originates from hard-coded fallback objects in Flutter feature services**. When API requests fail (e.g. 401 Unauthorized or network timeouts), service methods catch all exceptions (`catch (_)`) and silently return hard-coded mock objects rather than surfacing error/empty states.
2. **Database Verification**: The PostgreSQL database (`warmpath_db`) contains **0 user rows**, **0 giver profiles**, **0 sessions**, **0 ledger entries**, and **0 sponsored seats**. None of the displayed data originates from seed scripts or database rows.
3. **Authentication Boundary**: The Flutter application router (`app_router.dart`) contains no authentication guard or redirect on `/`. When signed out, the main shell is completely reachable. Unauthenticated requests sent to the backend lack Authorization headers; when backend endpoints return 401 Unauthorized, Flutter catch blocks substitute fake user data, resulting in the Profile tab showing "Sign In / Register" while adjacent tabs render user-specific mock records.

---

## 2. Fabricated Content Findings Table

| # | Item | Source Classification | Evidence (File & Line / DB Details) | Owner Role | Proposed Action |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **1** | **People shown on Discover**: Aarav Sharma, Sneha Patel, Priya Verma, Kabir Mehta, Dr. Vikram Sen, Ananya Deshmukh, with companies, batches, ratings (4.9, 4.8, 5.0) and sessions (34, 18, 56, 39, 65, 29). | **Hard-coded in Flutter** | • `app/lib/features/discover/services/discover_service.dart:58-75` (Priya Verma, 4.92, 56 sess)<br>• `discover_service.dart:80-97` (Kabir Mehta, 4.95, 39 sess)<br>• `discover_service.dart:108-125` (Dr. Vikram Sen, 4.98, 65 sess)<br>• `discover_service.dart:130-147` (Ananya Deshmukh, 4.8, 29 sess)<br>• `discover_service.dart:160-181` (Aarav Sharma, 4.9, 34 sess)<br>• `discover_service.dart:192-212` (Sneha Patel, 4.75, 18 sess)<br>• `discover_service.dart:222-243` (Rohan Gupta, 4.88, 22 sess)<br>• `app/lib/features/discover/discover_page.dart:264` (`giver_name: 'Aarav Sharma'`)<br>• DB: `SELECT count(*) FROM giver_profiles;` = **0** | **M2** (`app/lib/features/discover/`) | Delete `_getFallbackRecommendations()` and remove silent `catch (_)`. Throw typed `AppException` so Riverpod AsyncValue renders `EmptyState(title: "Add Your Resume to Get Matches")` or `ErrorState(onRetry: ...)`. Ban all names in `scripts/banned_strings.txt`. |
| **2** | **Sessions on Inbox tab**: Scheduled Oct 18 4:58 AM, completed Oct 17 3:58 AM; Requests at 3:44 AM ("Seeking guidance on backend microservices architecture...") and 1:59 AM ("Hi Aarav, looking for guidance on Azure cloud..."). | **Hard-coded in Flutter** | • `app/lib/features/sessions/sessions_api_service.dart:14-35` (`_demoSessions`: `sess_aarav_live` scheduled at `now + 1h`, `sess_sneha_done` completed at `now - 24h`)<br>• `sessions_api_service.dart:37-58` (`_demoRequests`: `req_incoming_aditya` at `now - 15m`, `req_outgoing_aarav` at `now - 2h`)<br>• `sessions_api_service.dart:60-75` (`_demoMessages`: `msg_1`, `msg_2`)<br>• `sessions_api_service.dart:135-141` (`listRequests()` returns `_demoRequests` on catch)<br>• `sessions_api_service.dart:329-331` (`listMySessions()` returns `_demoSessions` on catch)<br>• DB: `sessions` table does not exist; backend returns 401 | **M3** (`app/lib/features/sessions/`) | Delete in-memory `_demoSessions`, `_demoRequests`, and `_demoMessages` static lists. Return empty lists `[]` on empty backend, or propagate error state to display `EmptyState(title: "No sessions yet")`. Ban IDs and intent strings in `scripts/banned_strings.txt`. |
| **3** | **Wallet balance & ledger**: 3 credits (2 paid, 1 affinity), ledger rows `Txn #txn_101` (purchase, +2 credits, ₹499) and `Txn #txn_102` (reserve, -1 credit, ₹250). | **Hard-coded in Flutter** | • `app/lib/features/plans_wallet/services/plans_wallet_api_service.dart:123-164` (in `getWallet()` `catch (_)` block returning fake `WalletModel` with `txn_101`, `txn_102`, `txn_103`)<br>• DB: credits/ledger table does not exist; 0 rows | **M4** (`app/lib/features/plans_wallet/`) | Delete `WalletModel(...)` mock fallback in `getWallet()`. Return `WalletModel.empty()` (0 credits, empty ledger) or propagate typed API error. Ban `txn_101`, `txn_102`, `txn_103` in `scripts/banned_strings.txt`. |
| **4** | **Earnings screen**: ₹1200 available, ₹500 pending, ₹3400 paid out, subtitle "Successfully transferred to bank account". | **Hard-coded in Flutter** | • `app/lib/features/plans_wallet/services/plans_wallet_api_service.dart:175-184` (in `getEarnings()` `catch (_)` block returning fake `EarningsModel(availableInr: 1200, pendingInr: 500, paidOutInr: 3400, ...)`<br>• `app/lib/features/plans_wallet/pages/earnings_page.dart:187` (`subtitle: 'Successfully transferred to bank account'`)<br>• DB: 0 payout or earnings rows | **M4** (`app/lib/features/plans_wallet/`) | Delete mock `EarningsModel` in `getEarnings()`; return `EarningsModel.empty()`. In `earnings_page.dart:187`, only render transfer subtitle when genuine payout records exist. Ban string in `scripts/banned_strings.txt`. |
| **5** | **Sponsored seat**: "VIPS-TC, 2 of 2 credits remaining". | **Hard-coded in Flutter** | • `app/lib/features/plans_wallet/services/plans_wallet_api_service.dart:234-248` (in `getSponsoredSeats()` `catch (_)` block returning fake `SponsoredSeatModel(id: 'seat_1', institutionId: 'inst_vips', institutionName: 'VIPS-TC', creditsGranted: 2, creditsRemaining: 2)`)<br>• `app/lib/features/plans_wallet/pages/earnings_page.dart:406` (`'${seat.creditsRemaining} of ${seat.creditsGranted} credits remaining'`)<br>• DB: 0 sponsored seat rows | **M4** (`app/lib/features/plans_wallet/`) | Delete mock `SponsoredSeatModel` in `getSponsoredSeats()`; return empty list `[]`. Ban `seat_1` and `inst_vips` in `scripts/banned_strings.txt`. |
| **6** | **Marketing Claims**: "Payment gateway is simulated", "Unlimited Campus Connects", "2x faster responses", "3x faster responses", "40+ startups", "Honest guarantee". | **Hard-coded in Flutter** | • "Payment gateway is simulated": `app/lib/features/plans_wallet/pages/plans_page.dart:327`<br>• "Unlimited Campus Connects": `app/lib/features/plans_wallet/widgets/plan_card.dart:154`<br>• "3x faster responses": `app/lib/features/plans_wallet/models/plan_model.dart:55`<br>• "2x faster responses": `app/lib/features/plans_wallet/models/plan_model.dart:57`<br>• "40+ startups": `app/lib/features/discover/services/discover_service.dart:136, 146, 148`<br>• "Honest guarantee": `app/lib/features/plans_wallet/widgets/plan_card.dart:192` | **M4** (`plans_wallet`), **M2** (`discover`) | Remove fabricated marketing claims. Align with `PROJECT_CONTEXT.md` §4 & §27 ("Test mode: no real money moves"), request priority labels ("High Priority (Level 2)", "VIP Priority (Level 3)"), and factual free campus tier descriptions. Ban all 6 strings in `scripts/banned_strings.txt`. |
| **7** | **Literal text `${s.durationMinutes}` on session cards**: Session cards displayed literal syntax `${s.durationMinutes} mins`. | **Hard-coded in Flutter** (String interpolation bug) | • `app/lib/features/sessions/sessions_page.dart:120`: committed in `8d62657` as `'\${s.durationMinutes} mins'`, where an escaped dollar sign prevented Dart interpolation and printed literal variable syntax to the UI widget. | **M3** (`app/lib/features/sessions/`) | Use unescaped string interpolation `'${s.durationMinutes} mins'`. Add widget test asserting card renders numerical minutes (e.g. "20 mins"). Ban `\${s.durationMinutes}` in `scripts/banned_strings.txt`. |

---

## 3. Authentication & Router Audit

### 3.1 Root Cause of Profile Tab vs Adjacent Tabs Asymmetry

The `ProfilePage` (`app/lib/features/auth/pages/profile_page.dart`) explicitly checks authentication state via `ref.watch(authProvider)` and `SecureStorageService.getAccessToken()`. When signed out, it renders "Sign In / Register".

In contrast, adjacent tabs:
1. **Discover** (`/`): Managed by `DiscoverPage`, which requests `/recommendations`.
2. **Inbox** (`/sessions`): Managed by `SessionsPage`, which requests `/me/sessions` and `/requests`.
3. **Wallet** (`/plans-wallet`): Managed by `PlansPage` / `EarningsPage`, which request `/me/wallet`, `/me/earnings`, and `/sponsored-seats`.

When signed out, `DioClient` attaches no token. The backend correctly returns `401 Unauthorized` (or `500` on unmigrated tables). Rather than propagating this unauthorized error or triggering an auth redirect, **each feature service caught the error in a `catch (_)` block and returned hard-coded fake data**. Thus, the application rendered populated user screens on three tabs while the Profile tab truthfully showed the user was signed out.

### 3.2 Flutter Router Redirect Analysis

- **Inspection of `app/lib/app_router.dart`**:
  ```dart
  final GoRouter appRouter = GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      ...discoverRoutes,
      ...authRoutes,
      ...safetyRoutes,
      ...onboardingRoutes,
      ...availabilityRoutes,
      ...sessionsRoutes,
      ...ratingsRoutes,
      ...plansWalletRoutes,
    ],
  );
  ```
- **Finding**: `GoRouter` does not configure a `redirect` callback or authentication guard.
- **Reachability**: The main navigation shell (`/`, `/sessions`, `/plans-wallet`) is **fully reachable when signed out**.

### 3.3 API Client Authorization Header Analysis

- **Inspection of `app/lib/core/api/dio_client.dart`**:
  ```dart
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await SecureStorageService.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      return handler.next(options);
    },
    ...
  ));
  ```
- **Finding**:
  - The API client **does attach the Authorization header globally** for all features whenever a token exists in `SecureStorageService`.
  - When the user is signed out (`token == null`), `options.headers['Authorization']` is omitted.
  - Individual services (`DiscoverService`, `SessionsApiService`, `PlansWalletApiService`, `OnboardingService`) instantiate `DioClient().dio` properly and do not strip the header.

---

## 4. Backend GET Endpoint Security Audit (Without Token)

Every GET endpoint specified in `PROJECT_CONTEXT.md` Section 7 was tested via `curl.exe` without an Authorization header against the running backend (`http://localhost:8000`).

### 4.1 Endpoint Results Summary

| Endpoint | HTTP Status | Response Snippet / Behavior | Auth Behavior Assessment |
| :--- | :---: | :--- | :--- |
| `GET /me` | 404* / 401 | `{"detail":"Not Found"}` (*auth module unloaded due to missing container package `email-validator`) | Code requires `get_current_user` (returns 401 when auth router is loaded) |
| `GET /me/data-export` | 404* / 401 | `{"detail":"Not Found"}` | Code requires `get_current_user` |
| `GET /institutions` | 404* / 200 | `{"detail":"Not Found"}` | Public reference endpoint; returns `[]` when table is unpopulated |
| `GET /verification/status` | 404* / 401 | `{"detail":"Not Found"}` | Code requires `get_current_user` |
| `GET /me/trust` | 401 | `{"error":{"code":"unauthorized","message":"Authentication to..."}}` | **Properly protected with 401** |
| `GET /admin/moderation/queue` | 401 | `{"error":{"code":"unauthorized","message":"Authentication to..."}}` | **Properly protected with 401** |
| `GET /admin/verification/queue` | 401 | `{"error":{"code":"unauthorized","message":"Authentication to..."}}` | **Properly protected with 401** |
| `GET /admin/audit-log` | 401 | `{"error":{"code":"unauthorized","message":"Authentication to..."}}` | **Properly protected with 401** |
| `GET /resume/profile` | 500 | `Internal Server Error` | **Security defect**: `get_current_user_id` falls back to dev UUID `00000000-0000-0000-0000-000000000001` instead of raising 401. Crashed on missing table. |
| `GET /me/intent` | 500 | `Internal Server Error` | **Security defect**: falls back to dev UUID instead of 401. |
| `GET /me/consents` | 500 | `Internal Server Error` | **Security defect**: falls back to dev UUID instead of 401. |
| `GET /recommendations` | 401 | `{"error":{"code":"unauthorized","message":"Authentication required"}}` | **Properly protected with 401** |
| `GET /givers/{id}` | 404 | `{"error":{"code":"giver_profile_not_found","message":"No giv..."}}` | Public profile lookup; properly returns 404 for non-existent giver |
| `GET /me/giver-profile` | 401 | `{"error":{"code":"unauthorized","message":"Authentication required"}}` | **Properly protected with 401** |
| `GET /me/availability` | 401 | `{"error":{"code":"unauthorized","message":"Authentication required"}}` | **Properly protected with 401** |
| `GET /presence` | 401 | `{"error":{"code":"unauthorized","message":"Authentication required"}}` | **Properly protected with 401** |
| `GET /requests` | 401 | `{"error":{"code":"unauthorized","message":"Authentication required"}}` | **Properly protected with 401** |
| `GET /requests/{id}` | 401 | `{"error":{"code":"unauthorized","message":"Authentication required"}}` | **Properly protected with 401** |
| `GET /givers/{id}/slots` | 401 | `{"error":{"code":"unauthorized","message":"Authentication required"}}` | **Properly protected with 401** |
| `GET /requests/{id}/messages` | 401 | `{"error":{"code":"unauthorized","message":"Authentication required"}}` | **Properly protected with 401** |
| `GET /sessions/{id}` | 401 | `{"error":{"code":"unauthorized","message":"Authentication required"}}` | **Properly protected with 401** |
| `GET /me/sessions` | 401 | `{"error":{"code":"unauthorized","message":"Authentication required"}}` | **Properly protected with 401** |
| `GET /givers/{id}/rating-summary` | 500 | `Internal Server Error` | Public endpoint; failed closed due to missing DB table |
| `GET /me/band` | 401 | `{"error":{"code":"unauthorized","message":"Authentication required"}}` | **Properly protected with 401** |
| `GET /admin/disputes` | 401 | `{"error":{"code":"unauthorized","message":"Authentication required"}}` | **Properly protected with 401** |
| `GET /plans` | 500 | `Internal Server Error` | Public plans listing; failed on missing `plans` table |
| `GET /me/subscription` | 500 | `Internal Server Error` | **Security defect**: `credits/router.py:57` falls back to dev UUID instead of 401. |
| `GET /me/wallet` | 500 | `Internal Server Error` | **Security defect**: falls back to dev UUID instead of 401. |
| `GET /me/earnings` | 500 | `Internal Server Error` | **Security defect**: falls back to dev UUID instead of 401. |
| `GET /sponsored-seats` | 500 | `Internal Server Error` | Failed closed on missing table |
| `GET /admin/dashboard/overview` | 500 | `Internal Server Error` | Failed closed on missing table |
| `GET /admin/dashboard/skill-gap` | 500 | `Internal Server Error` | Failed closed on missing table |
| `GET /admin/dashboard/safety-summary` | 500 | `Internal Server Error` | Failed closed on missing table |
| `GET /admin/dashboard/seats` | 500 | `Internal Server Error` | Failed closed on missing table |

### 4.2 Key Endpoint Findings

1. **Zero endpoints returned 200 with data** when called without a token.
2. Modules `trust`, `matching`, `availability`, `sessions`, and `ratings` strictly enforce authentication and return `401 Unauthorized` when the token is missing.
3. Modules `resume` (`resume/router.py:39`) and `credits` (`credits/router.py:57`) contain a critical dev fallback: when no token or header is present, they return `00000000-0000-0000-0000-000000000001` instead of raising an HTTP 401 AppError. These must be updated to raise 401 in production and test environments.

---

## 5. Banned Strings Added to CI Guard

The following strings have been added to `scripts/banned_strings.txt` to ensure CI blocks any reintroduction:
- **Fabricated Giver Names**: `Aarav Sharma`, `Sneha Patel`, `Priya Verma`, `Kabir Mehta`, `Dr. Vikram Sen`, `Ananya Deshmukh`, `Rohan Gupta`
- **Fabricated Session & Request IDs**: `sess_aarav_live`, `sess_sneha_done`, `req_demo_aarav`, `req_demo_sneha`, `req_incoming_aditya`, `req_outgoing_aarav`
- **Fabricated Request Intent Strings**: `Seeking guidance on backend microservices architecture`, `Hi Aarav, looking for guidance on Azure cloud`
- **Fabricated Financial & Seat IDs**: `txn_101`, `txn_102`, `txn_103`, `seat_1`, `inst_vips`
- **Fabricated Marketing & Status Claims**: `Payment gateway is simulated`, `Unlimited Campus Connects`, `2x faster responses`, `3x faster responses`, `40+ startups`, `Honest guarantee`, `Successfully transferred to bank account`
- **Escaped Variable Syntax**: `\${s.durationMinutes}`

---

## 6. Action Items by Role

### Role M1 (Platform, Auth & Routing)
- [ ] Add authentication guard / redirect to `app/lib/app_router.dart`: unauthenticated users visiting protected routes should redirect to `/auth/login` or display a structured guest view.
- [ ] Ensure `email-validator` is in `backend/requirements.txt` and Dockerfile builds so `auth` router loads reliably.

### Role M2 (Discover & Resume)
- [ ] In `app/lib/features/discover/services/discover_service.dart`, remove `_getFallbackRecommendations()` and do not catch exceptions silently.
- [ ] In `backend/app/modules/resume/router.py:21`, remove fallback `uuid.UUID("00000000-0000-0000-0000-000000000001")`; raise 401 Unauthorized when unauthenticated.

### Role M3 (Sessions & Availability)
- [ ] In `app/lib/features/sessions/sessions_api_service.dart`, remove `_demoSessions`, `_demoRequests`, and `_demoMessages`.
- [ ] Maintain unescaped string interpolation `'${s.durationMinutes} mins'` in `sessions_page.dart`.

### Role M4 (Plans, Wallet & Earnings)
- [ ] In `app/lib/features/plans_wallet/services/plans_wallet_api_service.dart`, remove mock fallbacks in `getWallet()`, `getEarnings()`, and `getSponsoredSeats()`. Return empty models (`WalletModel.empty()`, `EarningsModel.empty()`, `[]`).
- [ ] In `backend/app/modules/credits/router.py:57`, remove fallback dev user ID; raise 401 Unauthorized when unauthenticated.
- [ ] In `plan_card.dart` and `plans_page.dart`, replace unapproved promotional claims with canonical contract lines.
