# Backend Architecture (Current)

This document describes the **current** NestJS backend architecture for Alpha Motors (auto.tm): runtime topology, key modules, critical flows, and known risks.

For Auth/OTP endpoint contracts (payloads and responses), see [API_REFERENCE.md](API_REFERENCE.md).

## System Context

- **Mobile app**: Flutter (iOS/Android)
- **Backend**: NestJS HTTP API + Socket.IO gateways
- **Database**: PostgreSQL (schema via Sequelize migrations)
- **Media**: uploads stored on disk (mounted volume in Docker)

## Runtime Topology

| Component | Default | Notes |
|---|---:|---|
| HTTP API | `:3080` | Swagger at `/api-docs` |
| Client Socket.IO | `:3090` | Chat/notifications + phone↔socket mapping |
| SMS Device Socket.IO | `:3091` (`/sms`) | Physical SMS device gateway |
| PostgreSQL | `:5432` | Container-to-container via `db:5432` |

## Key Backend Modules

- **Auth**: refresh token hashing/rotation, `/auth/me`, `/auth/refresh`, `/auth/logout`
- **OTP**: create/verify OTP codes persisted in `otp_codes`
- **SMS**: dispatch OTP SMS via a connected physical device (Socket.IO)
- **Chat**: client gateway (3090) for events/notifications; OTP generation is not here

## OTP Flow (Current)

### 1) Send OTP

1. Client calls `POST /api/v1/otp/send` with `{ "phone": "+993..." }`.
2. Backend normalizes phone, creates a new OTP record in `otp_codes`:
   - OTP is generated (test numbers may receive a deterministic code)
   - OTP is hashed (bcrypt)
   - Prior unconsumed OTPs for the same phone/purpose are invalidated
   - Expiration is enforced via `OTP_TTL_SECONDS` (default 300s)
3. Backend attempts SMS dispatch (unless test number): `SmsService` → `SmsGateway`.

Rate limiting: Throttler per IP (e.g. 3 per 60s for send); per-phone rate limit via `OTP_PHONE_RATE_LIMIT_WINDOW_MS` / `OTP_PHONE_RATE_LIMIT_MAX` (returns `OTP_RATE_LIMIT` when exceeded).

### 2) Verify OTP

1. Client calls `POST /api/v1/otp/verify` with `{ "phone": "+993...", "otp": "12345" }`.
2. Backend checks the latest valid OTP entry:
   - Enforces expiration (`expiresAt`) and attempt limits (`OTP_MAX_ATTEMPTS`)
   - Compares code using bcrypt
   - Marks OTP consumed on success
3. Backend ensures user exists and is activated, then issues tokens:
   - Access token: 15 minutes
   - Refresh token: 7 days

Rate limiting (Throttler): verify is limited per IP.

### 3) Refresh Rotation

`POST /api/v1/auth/refresh` rotates refresh tokens:
- Stores only a bcrypt hash of the latest refresh token on the user record
- Detects token reuse (mismatch) and revokes by clearing the stored hash

## Physical SMS Device Gateway (Current)

OTP SMS delivery can be handled by a **physical Android phone** running a custom "SMS device" app.

- Server gateway: [backend/src/sms/sms.gateway.ts](../src/sms/sms.gateway.ts)
- Port: `3091`
- Namespace: `/sms`

### Core events

| Direction | Event | Purpose |
|---|---|---|
| Device → Server | `sms:register` | Device registers; optional auth token |
| Server → Device | `sms:send` | Request to send SMS (phone + text + correlationId) |
| Device → Server | `sms:ack` | Acknowledges send result (`sent`/`delivered`/`failed`) |
| Device → Server | `sms:status` | Optional heartbeats/device metrics |
| Server → Device | `sms:ping` | Keep-alive |

Delivery tracking:
- Backend uses correlation IDs to match `sms:ack` to a request and update `otp_codes.dispatchStatus`.

Platform note:
- iOS typically restricts silent SMS sending; plan for Android devices.

## Migrations and Startup

- Migrations live in [backend/migrations/](../migrations/) and are executed on container start via [backend/docker/entrypoint.sh](../docker/entrypoint.sh).
- Seed data (currencies + brands/models) is required for core flows; see [DEVELOPMENT_SETUP.md](DEVELOPMENT_SETUP.md).
- For full schema and table reference, see [DATABASE.md](DATABASE.md).

## Known Risks / Flaws (Current)

- WebSocket hardening: wide-open CORS is convenient but not ideal for production.
- SMS device auth: if `SMS_DEVICE_AUTH_TOKEN` is not set, any client could register as an SMS device.
- Reliability: a single physical phone is a single point of failure; add monitoring and consider multiple devices per region.
- Logging: OTP codes must never be logged; mask phone numbers in logs.

