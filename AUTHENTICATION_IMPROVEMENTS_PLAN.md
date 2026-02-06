# Authentication Improvements Plan

## Purpose
Align the OTP-based auth flow with real-world practices, reduce token drift, and standardize session validation across frontend and backend.

## Current End-to-End Flow (Snapshot)
### Backend
- OTP send/verify: [backend/src/otp/otp.controller.ts](backend/src/otp/otp.controller.ts), [backend/src/otp/otp.service.ts](backend/src/otp/otp.service.ts)
- Token refresh/rotation + reuse detection: [backend/src/auth/auth.service.ts](backend/src/auth/auth.service.ts)
- Access validation + deleted-user handling: [backend/src/guards/auth.gurad.ts](backend/src/guards/auth.gurad.ts)
- Session validation endpoint: [backend/src/auth/auth.controller.ts](backend/src/auth/auth.controller.ts)

### Frontend
- OTP flow and token persistence: [auto.tm-main/lib/services/auth/auth_service.dart](auto.tm-main/lib/services/auth/auth_service.dart)
- Interceptor refresh + USER_DELETED handling: [auto.tm-main/lib/services/network/api_client.dart](auto.tm-main/lib/services/network/api_client.dart)
- Session boot check: [auto.tm-main/lib/app.dart](auto.tm-main/lib/app.dart)
- Registration controller: [auto.tm-main/lib/screens/auth_screens/register_screen/controller/register_controller.dart](auto.tm-main/lib/screens/auth_screens/register_screen/controller/register_controller.dart)

## High Priority (Start Here)
### ✅ Implemented in this step
1) Centralized token persistence using `TokenStore` (secure storage) with **temporary legacy mirroring** to keep older screens working.
   - [auto.tm-main/lib/services/token_service/token_store.dart](auto.tm-main/lib/services/token_service/token_store.dart)
2) Moved profile fetch to `ApiClient` so refresh/deleted-user logic is consistent.
   - [auto.tm-main/lib/screens/profile_screen/controller/profile_controller.dart](auto.tm-main/lib/screens/profile_screen/controller/profile_controller.dart)
3) Removed legacy token writes in the OTP registration controller.
   - [auto.tm-main/lib/screens/auth_screens/register_screen/controller/register_controller.dart](auto.tm-main/lib/screens/auth_screens/register_screen/controller/register_controller.dart)

### Next high-priority follow-up
- Remove remaining direct `GetStorage` token reads and migrate all API calls to `ApiClient`.
- Once done, drop the legacy token mirror in `TokenStore`.

## Medium Priority
1) Add structured error codes for OTP failures (e.g., `OTP_INVALID`) to match docs.
   - [backend/src/otp/otp.service.ts](backend/src/otp/otp.service.ts)
   - [backend/src/otp/otp.controller.ts](backend/src/otp/otp.controller.ts)
2) Add per-phone throttling and optional device fingerprint or captcha on OTP endpoints.

## Low Priority
1) Add per-session records (`jti`) for multi-device tracking, revocation, and audit trail.
2) Disable test OTP return payloads in production.

## Migration Checklist
- [ ] Replace `GetStorage` access token usage across controllers with `TokenStore` or `ApiClient`.
- [ ] Remove `TokenService` usage or convert it into a thin compatibility wrapper.
- [ ] Remove legacy token mirror once all controllers are migrated.
- [ ] Validate `/auth/me` boot flow still works under refresh and deleted-user scenarios.

## Acceptance Criteria
- All authenticated requests use `ApiClient` with token refresh and `USER_DELETED` handling.
- Only one token storage source of truth remains (secure storage).
- OTP error responses include stable error codes for frontend handling.
