# Alpha Motors — Roadmap & Improvement Plans

High-level plans and follow-ups. Implementation details live in the codebase and in [backend/docs/](backend/docs/).

**Implementation status** (last verified against codebase): See [Implementation status](#implementation-status) below.

**Access model & TokenStore:** For the roadmap that implements [public vs authenticated access](ACCESS_MODEL.md) (guest browsing, backend public endpoints, TokenStore alignment) and the **alignment audit of the current mobile app**, see [docs/ACCESS_MODEL_ROADMAP.md](ACCESS_MODEL_ROADMAP.md).

---

## Implementation status

Verified against the current codebase.

### Already implemented

| Item | Status | Notes |
|------|--------|-------|
| **TokenStore** | Done | `lib/services/token_service/token_store.dart` — `flutter_secure_storage` only; no legacy GetStorage mirror in code. |
| **ApiClient** | Done | `lib/services/network/api_client.dart` — interceptor attaches token, handles `TOKEN_EXPIRED` (refresh + retry) and `USER_DELETED` (force logout). |
| **Register controller** | Done | Tokens persisted by AuthService via TokenStore; no direct token writes to GetStorage. Register still uses GetStorage for `user_phone` / `user_location` only. |
| **Deleted user handling** | Done | Backend: `auth.gurad.ts` returns `401 USER_DELETED`. Frontend: ApiClient interceptor force-logs out. See [docs/TESTING.md](TESTING.md). |
| **OTP error codes (verify)** | Done | Backend returns `OTP_INVALID`, `OTP_NOT_FOUND`, `OTP_MAX_ATTEMPTS` in verify flow (`otp.service.ts`). |
| **OTP rate limit code** | Done | Send returns `OTP_RATE_LIMIT` (429) when per-phone or IP limit exceeded. |
| **Per-phone throttling** | Done | Backend: `OTP_PHONE_RATE_LIMIT_WINDOW_MS`, `OTP_PHONE_RATE_LIMIT_MAX` in `otp.service.ts`. |
| **Boot auth check** | Done | `app.dart` calls `GET /auth/me` via ApiClient (which handles refresh and USER_DELETED). |
| **TokenService** | Wrapper only | `token_service.dart` is deprecated and delegates to TokenStore; can be removed when no callers remain. |

### Implemented this round

| Item | Status | Notes |
|------|--------|-------|
| **GetStorage token cleanup** | Done | `profile_controller.dart` logout fallback now uses TokenStore.clearAll() when AuthService not registered; no longer touches ACCESS_TOKEN/REFRESH_TOKEN in GetStorage. |
| **OTP_INVALID_PHONE in send** | Done | `backend/src/otp/otp.service.ts` now returns 400 with `{ code: "OTP_INVALID_PHONE", message: "Phone number is required" }` when phone is missing. |
| **ApiClient migration (partial)** | Done | Home (banner, category, home), search, post_details, comments, favorites, notification_service now use ApiClient.dio for authenticated requests. |

### Not yet done

| Item | Status | Notes |
|------|--------|-------|
| **All API calls via ApiClient** | Partial | Remaining: `filter_controller`, `blog_controller`, `add_blog_controller`, `add_blog_screen`, `post_controller` (many call sites) still use TokenStore + manual HTTP. |
| **Legacy token mirror** | N/A | No legacy mirror in TokenStore; nothing to remove. |

---

## Authentication Improvements (Current Plan)

**Goal:** Align OTP auth with best practices, reduce token drift, standardize session validation across frontend and backend.

### High priority (next)

- Replace remaining GetStorage token usage (profile_controller logout fallback) with TokenStore-only cleanup.
- Migrate all API calls to go through ApiClient (Dio) so every request gets token refresh and USER_DELETED handling.
- Optionally add `code: "OTP_INVALID_PHONE"` to `/otp/send` 400 response for consistency with API_REFERENCE.

### Medium priority

- Structured OTP error codes: verify is done; ensure send returns `OTP_INVALID_PHONE` when phone is missing/invalid.
- Optional device fingerprint or captcha on OTP endpoints (per-phone throttling is already implemented).

### Low priority

- Per-session records (`jti`) for multi-device tracking, revocation, and audit.
- Disable test OTP response payloads in production where not needed.

### Migration checklist (auth)

- [x] Remove GetStorage token cleanup from profile_controller logout fallback; use TokenStore only (or AuthService.logout only).
- [x] TokenService is a thin wrapper; remove when no callers remain (optional).
- [x] No legacy token mirror in TokenStore to remove.
- [x] Confirm `/auth/me` boot flow works under refresh and deleted-user scenarios.
- [x] Migrate key controllers to ApiClient.dio (home, search, post_details, comments, favorites, notification_service).
- [ ] Migrate remaining: filter_controller, blog (controller + add_blog), post_controller.

### Acceptance criteria

- All authenticated requests use ApiClient (Dio) with token refresh and USER_DELETED handling. (Partially met; post/filter/blog still to migrate.)
- Single source of truth for token storage (TokenStore / secure storage). (Met.)
- OTP error responses include stable error codes including OTP_INVALID_PHONE for send. (Met.)

---

## Key file references (auth)

| Layer | File | Purpose |
|-------|------|---------|
| Backend OTP | `backend/src/otp/otp.controller.ts`, `otp.service.ts` | Send/verify OTP |
| Backend Auth | `backend/src/auth/auth.service.ts` | Refresh/rotation, reuse detection |
| Backend Guard | `backend/src/guards/auth.gurad.ts` | JWT + user existence, USER_DELETED |
| Backend Session | `backend/src/auth/auth.controller.ts` | `/auth/me` |
| Flutter OTP | `auto.tm-main/lib/services/auth/auth_service.dart` | OTP flow, token persistence |
| Flutter API | `auto.tm-main/lib/services/network/api_client.dart` | Interceptor, refresh, USER_DELETED |
| Flutter Boot | `auto.tm-main/lib/app.dart` | Session check on startup |
| Flutter Tokens | `auto.tm-main/lib/services/token_service/token_store.dart` | Secure storage |

---

## Other areas (future)

- **WebSocket/SMS gateway:** Harden CORS and SMS device auth (e.g. `SMS_DEVICE_AUTH_TOKEN`); consider multiple devices per region.
- **Logging:** Never log OTP codes; mask phone numbers in logs.
- **Database:** Optional Redis for user-existence checks if traffic grows.

These are noted in [backend/docs/ARCHITECTURE.md](backend/docs/ARCHITECTURE.md) under “Known Risks / Flaws”.
