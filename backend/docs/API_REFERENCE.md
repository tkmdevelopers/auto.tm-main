# Alpha Motors — API Reference

This document is the single source of truth for the Alpha Motors backend authentication API. Use it for Flutter integration, curl testing, Postman collections, or any other client.

Swagger/OpenAPI docs are also available at `/api-docs` when the server is running.

---

## Table of Contents

1. [Authentication Flow](#authentication-flow)
2. [Endpoints](#endpoints)
3. [Error Codes](#error-codes)
4. [Rate Limiting](#rate-limiting)
5. [Token Lifecycle](#token-lifecycle)
6. [Curl Smoke Tests](#curl-smoke-tests)
7. [Database Migration](#database-migration)
8. [Flutter Integration](#flutter-integration)

---

## Authentication Flow

All authentication uses phone-based OTP. There are no email/password endpoints.

```
  Client                        Backend
    |                              |
    |  POST /otp/send {phone}      |
    |----------------------------->|  generate OTP, dispatch SMS
    |         200 OK               |
    |<-----------------------------|
    |                              |
    |  POST /otp/verify {phone,otp}|
    |----------------------------->|  verify code, create user if new
    |  {accessToken, refreshToken} |
    |<-----------------------------|
    |                              |
    |  GET /auth/me (Bearer access)|
    |----------------------------->|  return user profile
    |         200 OK               |
    |<-----------------------------|
    |                              |
    |  ... access token expires ...|
    |                              |
    |  POST /auth/refresh          |
    |  (Bearer refreshToken)       |
    |----------------------------->|  rotate: new access + new refresh
    |  {accessToken, refreshToken} |
    |<-----------------------------|
    |                              |
    |  POST /auth/logout           |
    |  (Bearer accessToken)        |
    |----------------------------->|  revoke refresh token hash
    |         200 OK               |
    |<-----------------------------|
```

Test phone numbers (e.g. `+99361999999`) always accept OTP code `12345`.

---

## Endpoints

All paths are prefixed with `/api/v1`.

### OTP

| Method | Path | Body / Headers | Success Response |
|--------|------|----------------|------------------|
| POST | `/otp/send` | `{ "phone": "993XXXXXXXX" }` | `200` — request info (requestId, expiresAt) |
| POST | `/otp/verify` | `{ "phone": "993XXXXXXXX", "otp": "12345" }` | `200` — `{ accessToken, refreshToken }` |

### Auth

| Method | Path | Body / Headers | Success Response |
|--------|------|----------------|------------------|
| GET | `/auth/me` | Header: `Authorization: Bearer <accessToken>` | `200` — user profile object |
| POST | `/auth/refresh` | Header: `Authorization: Bearer <refreshToken>` | `200` — `{ accessToken, refreshToken }` (rotated pair) |
| POST | `/auth/logout` | Header: `Authorization: Bearer <accessToken>` | `200` — `{ message: "Successfully logged out" }` |

### Profile

| Method | Path | Body / Headers | Success Response |
|--------|------|----------------|------------------|
| PUT | `/auth` | Bearer access + JSON `{ name, location, email, phone }` | `200` — updated |
| POST | `/auth/avatar` | Bearer access + multipart `file` | `200` — avatar uuid |
| DELETE | `/auth/avatar` | Bearer access | `200` — deleted |
| PUT | `/auth/setFirebase` | Bearer access + `{ token }` | `200` — set |

---

## Error Codes

All authentication errors return HTTP **401** with a JSON body containing a `code` field:

| Code | Meaning |
|------|---------|
| `TOKEN_EXPIRED` | Access or refresh token has expired. Client should attempt a refresh. |
| `TOKEN_INVALID` | Token is malformed, missing, or not a valid JWT. |
| `TOKEN_REUSE` | A previously used refresh token was presented. The session has been revoked as a security precaution — the user must log in again. |
| `USER_DELETED` | The user account has been deleted by an administrator. The client must log out and clear all local data. |
| `OTP_INVALID` | The OTP code is wrong or expired. |

Admin-only endpoints return **403** with `code: "FORBIDDEN"` if the user is not an admin.

Rate-limited requests return **429** (see below).

---

## Rate Limiting

Rate limits are enforced per IP using `@nestjs/throttler`.

| Scope | Limit |
|-------|-------|
| OTP send (`POST /otp/send`) | 3 requests per 60 seconds |
| OTP verify (`POST /otp/verify`) | 5 requests per 60 seconds |
| All other endpoints (global) | 60 requests per 60 seconds |

When rate-limited, the response is:

```json
{
  "statusCode": 429,
  "message": "ThrottlerException: Too Many Requests"
}
```

---

## Token Lifecycle

| Token | TTL | Storage |
|-------|-----|---------|
| Access token | **15 minutes** | Signed JWT (HS256). Contains `{ uuid, phone }`. |
| Refresh token | **7 days** | Signed JWT (HS256). A **bcrypt hash** of the token is stored in the `users.refreshTokenHash` column. The plaintext token is never persisted server-side. |

### Rotation

Every call to `POST /auth/refresh`:

1. Validates the refresh JWT signature and expiry.
2. Compares `bcrypt(presentedToken)` against the stored `refreshTokenHash`.
3. If valid: issues a **new** access token and a **new** refresh token, stores the new hash, and returns both.
4. The old refresh token is immediately invalidated (single-use).

### Reuse Detection

If step 2 fails (hash mismatch), the server assumes the refresh token was stolen and replayed:

- The session is **revoked** (`refreshTokenHash` set to null).
- A `401 TOKEN_REUSE` error is returned.
- The legitimate user and the attacker are both forced to re-authenticate.

---

## Curl Smoke Tests

Run these in order against a local backend at `http://localhost:3080`.

```bash
# 1. Health check — Swagger docs load
curl -s http://localhost:3080/api-docs | head -5

# 2. Send OTP (test number)
curl -s -X POST http://localhost:3080/api/v1/otp/send \
  -H 'Content-Type: application/json' \
  -d '{"phone":"99361999999"}'

# 3. Verify OTP (test code: 12345) — save the tokens
TOKENS=$(curl -s -X POST http://localhost:3080/api/v1/otp/verify \
  -H 'Content-Type: application/json' \
  -d '{"phone":"99361999999","otp":"12345"}')
echo "$TOKENS"

ACCESS=$(echo "$TOKENS" | python3 -c "import sys,json; print(json.load(sys.stdin)['accessToken'])")
REFRESH=$(echo "$TOKENS" | python3 -c "import sys,json; print(json.load(sys.stdin)['refreshToken'])")

# 4. Get profile
curl -s http://localhost:3080/api/v1/auth/me \
  -H "Authorization: Bearer $ACCESS"

# 5. Refresh tokens (returns new pair; old refresh is now invalid)
NEW_TOKENS=$(curl -s -X POST http://localhost:3080/api/v1/auth/refresh \
  -H "Authorization: Bearer $REFRESH")
echo "$NEW_TOKENS"

# 6. Rate limit test — 4th request should return 429
for i in 1 2 3 4; do
  echo -n "Request $i: "
  curl -s -o /dev/null -w "%{http_code}" -X POST \
    http://localhost:3080/api/v1/otp/send \
    -H 'Content-Type: application/json' \
    -d '{"phone":"99361999999"}'
  echo
done

# 7. Logout (use the original access token)
curl -s -X POST http://localhost:3080/api/v1/auth/logout \
  -H "Authorization: Bearer $ACCESS"
```

---

## Database Migration

Migration `20260206000000-refresh-token-hash.js` applies the following changes to the `users` table:

| Change | Detail |
|--------|--------|
| Add column | `refreshTokenHash` (TEXT, nullable) — stores bcrypt hash of the current valid refresh token |
| Remove column | `refreshToken` (TEXT) — old plaintext storage, removed for security |

This is a **breaking change**: all existing sessions are invalidated. Users must log in again after this migration runs.

Run the migration:

```bash
# From backend/ directory (Postgres must be running)
npm run db:migrate
```

Verify:

```bash
docker exec auto_tm_postgres psql -U auto_tm -d auto_tm \
  -c "SELECT column_name FROM information_schema.columns
      WHERE table_name='users'
        AND column_name IN ('refreshToken','refreshTokenHash');"
# Expected: only refreshTokenHash
```

---

## Flutter Integration

The Flutter app centralizes all auth handling through three services registered in `main.dart`:

### TokenStore (`lib/services/token_service/token_store.dart`)

Encrypted persistence using `flutter_secure_storage` (Keychain on iOS, EncryptedSharedPreferences on Android). Stores `ACCESS_TOKEN`, `REFRESH_TOKEN`, and `USER_PHONE`.

### ApiClient (`lib/services/network/api_client.dart`)

Dio-based HTTP client with an interceptor that:

1. **Attaches** the access token to every request automatically.
2. **Intercepts** 401 responses with `code: "TOKEN_EXPIRED"`.
3. **Acquires a mutex** (only one refresh at a time, even with concurrent requests).
4. **Calls** `POST /auth/refresh` with the stored refresh token.
5. **Saves** the new token pair via TokenStore.
6. **Retries** the original failed request with the new access token.
7. **Force-logs out** (clears tokens, navigates to `/register`) if refresh fails.

### AuthService (`lib/services/auth/auth_service.dart`)

High-level OTP + session service. Uses `ApiClient.to.dio` for OTP POST calls and `TokenStore` for persistence. Exposes reactive `currentSession` for UI binding.

### Boot Auth Check (`lib/app.dart`)

On app launch, `AuthCheckPage` validates the session by calling `GET /auth/me` through the ApiClient (which will auto-refresh if the access token is expired). If validation fails entirely, the user is routed to `/register`.

---

## Quick Reference Card

```
POST /otp/send          { phone }                    → 200
POST /otp/verify        { phone, otp }               → { accessToken, refreshToken }
GET  /auth/me           Bearer <access>               → user profile
POST /auth/refresh      Bearer <refresh>              → { accessToken, refreshToken }
POST /auth/logout       Bearer <access>               → 200

Errors:  401 TOKEN_EXPIRED | TOKEN_INVALID | TOKEN_REUSE | OTP_INVALID
         429 Too Many Requests
         403 FORBIDDEN (admin routes)

Tokens:  access 15min  |  refresh 7d (rotated, hashed)
```
