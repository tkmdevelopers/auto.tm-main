# Backend Architecture (Current)

This document describes the **current** NestJS backend architecture for Alpha Motors (auto.tm): runtime topology, key modules, critical flows, and known risks.

For Auth/OTP endpoint contracts (payloads and responses), see [backend/API_REFERENCE.md](../API_REFERENCE.md).

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

Rate limiting (Throttler): send is limited per IP.

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
- Seed data (currencies + brands/models) is required for core flows; see [backend/docs/DEVELOPMENT_SETUP.md](DEVELOPMENT_SETUP.md).

## Known Risks / Flaws (Current)

- WebSocket hardening: wide-open CORS is convenient but not ideal for production.
- SMS device auth: if `SMS_DEVICE_AUTH_TOKEN` is not set, any client could register as an SMS device.
- Reliability: a single physical phone is a single point of failure; add monitoring and consider multiple devices per region.
- Logging: OTP codes must never be logged; mask phone numbers in logs.

---

<!--
# Backend Architecture Analysis

## Current Authentication Flow

### Dual Auth Paths (Problem: Fragmented)

The backend currently supports **two separate authentication mechanisms**:

1. **Phone + OTP Flow** (primary, used by mobile app)
   - `GET /api/v1/otp/send?phone=...` → generates OTP, stores it, emits via WebSocket
   - `GET /api/v1/otp/verify?phone=...&otp=...` → validates OTP, issues JWT tokens

2. **Email + Password Flow** (legacy, rarely used)
   - `POST /api/v1/auth/login` → email/password login with bcrypt
   - Returns same JWT structure as OTP flow

**Pain Point**: Two login paths create maintenance overhead and security inconsistency.

---

## OTP Architecture (Current State)

### Key Files

| File | Purpose |
|------|---------|
| `src/otp/otp.controller.ts` | HTTP endpoints for OTP send/verify |
| `src/otp/otp.service.ts` | OTP business logic, JWT issuance |
| `src/otp/otp.entity.ts` | `OtpTemp` Sequelize model |
| `src/chat/chat.gateway.ts` | OTP generation + WebSocket delivery |
| `src/auth/auth.entity.ts` | `User` model with `otp` column |

### OTP Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                         OTP Send Flow                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Mobile App                                                         │
│      │                                                              │
│      ▼                                                              │
│  GET /api/v1/otp/send?phone=+99361234567                           │
│      │                                                              │
│      ▼                                                              │
│  OtpController.sendOtp()                                           │
│      │                                                              │
│      ▼                                                              │
│  OtpService.sendOtp()                                              │
│      │                                                              │
│      ├──► Creates user if not exists (auto-registration)           │
│      │                                                              │
│      ▼                                                              │
│  ChatGateway.issueOtp(socketId, phone, registered=true)            │
│      │                                                              │
│      ├──► Generate 5-digit OTP (or 12345 for test numbers)         │
│      │                                                              │
│      ├──► Store OTP:                                               │
│      │    ├──► registered=true: UPDATE users SET otp=...           │
│      │    └──► registered=false: UPSERT otp_temp                   │
│      │                                                              │
│      └──► Emit to socket (if socketId exists):                     │
│           server.to(socketId).emit('recieveOtp', {otp, phone})     │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### OTP Storage (Problem: Split Storage)

OTP codes are stored in **two different locations**:

1. **`users.otp`** column — for registered users
2. **`otp_temp`** table — for unregistered users (phone as PK)

**Pain Points**:
- No OTP expiration/TTL — codes never expire
- No attempt tracking — unlimited guesses allowed
- Plaintext storage — OTP stored as-is, not hashed
- Split logic — verification must check both locations

### OTP Generation

Located in `ChatGateway.issueOtp()` (lines 56-109):

```typescript
// Random OTP: 5 digits (10000-99999)
const otp = Math.floor(Math.random() * 90000) + 10000;

// Deterministic test numbers return 12345:
// - ENV: TEST_OTP_NUMBERS (comma-separated)
// - ENV: TEST_OTP_PREFIX (default: '9936199999')
// - Hardcoded: 99361999999, 99361999991-99361999993
```

### OTP Verification & JWT Issuance

Located in `OtpService.checkOtp()`:

```typescript
// On successful OTP match:
// 1. Clear OTP: UPDATE users SET otp = null
// 2. Generate tokens:
//    - accessToken: 24h expiry
//    - refreshToken: 7d expiry
// 3. Store refresh token: UPDATE users SET refreshToken = ...
// 4. Return { accessToken, refreshToken }
```

---

## WebSocket Architecture (Current State)

### Configuration

- **Gateway**: `src/chat/chat.gateway.ts`
- **Port**: 3090 (separate from API port 3080)
- **CORS**: Enabled for all origins
- **Authentication**: None (unauthenticated)

### Socket Events

| Direction | Event | Purpose |
|-----------|-------|---------|
| Client → Server | `chat message` | Broadcast chat messages |
| Client → Server | `sendOtp` | Legacy OTP trigger (unused) |
| Server → Client | `recieveOtp` | Deliver OTP to client |
| Server → Client | `notification` | Push notifications |

### Critical Problem: Single Socket ID

```typescript
// chat.gateway.ts line 19
private socketId: string;

handleConnection(client: Socket) {
  this.socketId = client.id; // OVERWRITES previous!
}
```

**Only the last connected client receives OTPs!** If multiple users connect:
- User A connects → socketId = A
- User B connects → socketId = B (A's ID lost)
- User A requests OTP → delivered to User B

---

## Auth Module (Current State)

### Key Files

| File | Purpose |
|------|---------|
| `src/auth/auth.controller.ts` | Registration, login, profile endpoints |
| `src/auth/auth.service.ts` | User CRUD, email/password login |
| `src/auth/auth.entity.ts` | User Sequelize model |
| `src/auth/auth.dto.ts` | Request/response DTOs |

### User Entity Schema

```typescript
@Table({ tableName: 'users' })
export class User extends Model {
  uuid: string;           // PK
  name: string;
  email: string;          // unique, optional
  password: string;       // bcrypt hash (for email login)
  phone: string;          // unique
  status: boolean;        // activated via OTP verify
  role: 'admin'|'owner'|'user';
  otp: string;            // current OTP (plaintext!)
  refreshToken: string;   // current refresh token
  location: string;
  access: string[];       // permissions array
  firebaseToken: string;  // FCM token
  // Relations: posts, comments, avatar, vlogs, brands
}
```

### Endpoints

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| POST | `/auth/register` | None | Create user by phone |
| POST | `/auth/login` | None | Email/password login |
| GET | `/auth/refresh` | RefreshGuard | Get new access token |
| GET | `/auth/me` | AuthGuard | Get current user |
| PUT | `/auth` | AuthGuard | Update own profile |
| GET | `/auth/logout` | AuthGuard | Clear refresh token |
| POST | `/auth/avatar` | AuthGuard | Upload avatar |
| DELETE | `/auth/avatar` | AuthGuard | Delete avatar |
| GET | `/auth/users` | AdminGuard | List all users |
| GET | `/auth/:uuid` | AdminGuard | Get user by ID |
| PATCH | `/auth/:uuid` | AdminGuard | Update user (admin) |
| DELETE | `/auth/:uuid` | AdminGuard | Delete user |
| PUT | `/auth/setFirebase` | AuthGuard | Set FCM token |

---

## Database Migrations

### Migration Strategy

- **Migrations-only** approach (no `sequelize.sync()`)
- Auto-run via Docker entrypoint before app starts
- CLI commands: `npm run db:migrate`, `npm run db:migrate:undo`

### Migration Files (17 total)

**Active migrations** (create tables):

| File | Tables/Changes |
|------|----------------|
| `20250222002707-create-all.js` | `users` (initial) |
| `20250224091406-brands.js` | `brands` |
| `20250224181000-models.js` | `models` |
| `20250224182207-posts.js` | `posts` |
| `20250225110000-create-vlogs.js` | `vlogs` |
| `20250225120000-add-vlog-fields.js` | vlogs: tag, videoUrl, thumbnail |
| `20250225130000-create-notification-history.js` | `notification_history` |
| `20251011130000-create-comments.js` | `comments` |
| `20251023120000-create-taxonomy-and-subscriptions.js` | `banners`, `categories`, `subscriptions`, `subscription_order` |
| `20251023120100-create-media-and-aux-tables.js` | `photo`, `video`, `file`, `otp_temp`, `convert_prices` |
| `20251023120200-create-junction-tables.js` | `brands_user`, `photo_posts`, `photo_vlogs` |

**No-op migrations** (kept for history):
- `20250224184223-models.js`
- `20250224184629-models-complete.js`
- `20251009120000-add-reply-to-comments.js`
- `20251010000000-rename-posts-uudi-to-uuid.js`
- `20251012000000-rename-posts-uudi-and-fix-comments-fk.js`
- `20251023120300-align-vlog-and-junctions.js`

---

## Pain Points Summary

### 1. OTP Split Storage
- OTPs stored in both `users.otp` and `otp_temp`
- Verification logic duplicated

### 2. No OTP Security
- No expiration (codes valid forever)
- No attempt limiting (brute-force possible)
- Plaintext storage (security risk)

### 3. Single Socket ID
- Only last connected client tracked
- OTPs delivered to wrong users

### 4. Unauthenticated WebSocket
- No JWT/token validation on socket connection
- Anyone can connect and receive events

### 5. Dual Auth Mechanisms
- Phone+OTP and Email+Password both supported
- Unnecessary complexity

### 6. No Rate Limiting
- Unlimited OTP requests per phone
- No protection against abuse

### 7. Migration Sprawl
- 17 migrations with some obsolete
- Hard to understand current schema state

---

## Target Architecture (OTP-only Refactor)

### New OTP Schema (`otp_codes` table)

```sql
CREATE TABLE otp_codes (
  id UUID PRIMARY KEY,
  phone VARCHAR(20) NOT NULL,           -- E.164 format
  purpose VARCHAR(50) NOT NULL,         -- 'login', 'register', 'verify_phone'
  code_hash VARCHAR(255) NOT NULL,      -- bcrypt/argon2 hash
  expires_at TIMESTAMP NOT NULL,        -- TTL enforcement
  consumed_at TIMESTAMP,                -- NULL until verified
  attempts INT DEFAULT 0,               -- brute-force protection
  max_attempts INT DEFAULT 5,
  region VARCHAR(50),                   -- SMS routing key
  channel VARCHAR(20) DEFAULT 'sms',    -- delivery channel
  provider_message_id VARCHAR(255),     -- SMS provider reference
  dispatch_status VARCHAR(50),          -- 'pending', 'sent', 'failed'
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_otp_phone_purpose ON otp_codes(phone, purpose);
CREATE INDEX idx_otp_expires ON otp_codes(expires_at);
```

### Unified OTP Service API

```typescript
interface OtpService {
  // Create and dispatch OTP
  createOtp(params: {
    phone: string;
    purpose: 'login' | 'register' | 'verify_phone';
    region?: string;
  }): Promise<{ requestId: string; expiresAt: Date }>;

  // Verify OTP (marks consumed on success)
  verifyOtp(params: {
    phone: string;
    purpose: string;
    code: string;
  }): Promise<{ valid: boolean; userId?: string }>;
}
```

### SMS Gateway (Physical Device)

The SMS system uses a physical mobile phone that connects to the backend:

```
┌─────────────────────────────────────────────────────────────────────┐
│                     SMS Architecture                                │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Physical Phone (SMS Device)                                        │
│      │                                                              │
│      │ Connects via Socket.IO                                       │
│      ▼                                                              │
│  Backend (port 3091, /sms namespace)                               │
│      │                                                              │
│      ├──► sms:register - Device authenticates                      │
│      │                                                              │
│  OTP Request Flow:                                                 │
│      │                                                              │
│  1.  User requests OTP                                             │
│      │                                                              │
│  2.  OtpService.createOtp() → SmsService.sendOtpSms()              │
│      │                                                              │
│  3.  SmsGateway.sendSms() → emits 'sms:send' to device             │
│      │                                                              │
│  4.  Physical phone sends actual SMS via cellular network          │
│      │                                                              │
│  5.  Device emits 'sms:ack' with status                            │
│      │                                                              │
│  6.  OTP dispatch status updated in database                       │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

**Socket Events (port 3091, /sms namespace):**

| Direction | Event | Purpose |
|-----------|-------|---------|
| Device → Server | `sms:register` | Device authentication |
| Device → Server | `sms:ack` | SMS delivery acknowledgment |
| Device → Server | `sms:status` | Device heartbeat/status |
| Server → Device | `sms:send` | Request to send SMS |
| Server → Device | `sms:ping` | Keep-alive ping |

**Device Registration:**
```javascript
// Device connects and registers
socket.emit('sms:register', {
  authToken: 'your-auth-token',  // From SMS_DEVICE_AUTH_TOKEN env
  region: 'tm',                  // Region for routing
  deviceId: 'phone-1'           // Unique device identifier
});
```

### Auth Changes

- Remove `POST /auth/login` (email/password)
- Remove `password` column usage
- Keep `POST /auth/register` but make it OTP-triggered
- OTP verify → JWT issuance (single path)

---

## Files to Modify

### Phase 1: OTP Schema
- New: `src/otp/otp-codes.entity.ts`
- New: `migrations/YYYYMMDD-baseline.js`
- Delete: `src/otp/otp.entity.ts` (OtpTemp)
- Modify: `src/auth/auth.entity.ts` (remove `otp` column)

### Phase 2: OTP Service
- Rewrite: `src/otp/otp.service.ts`
- Modify: `src/otp/otp.controller.ts`
- Modify: `src/chat/chat.gateway.ts` (remove OTP logic)

### Phase 3: SMS Gateway
- New: `src/sms/sms.module.ts`
- New: `src/sms/sms-gateway.client.ts`
- New: `src/sms/sms.config.ts`

### Phase 4: Auth Cleanup
- Modify: `src/auth/auth.service.ts` (remove email login)
- Modify: `src/auth/auth.controller.ts` (remove login endpoint)
- Modify: `src/auth/auth.dto.ts` (remove LoginUser)

---

## Database Reset Procedure

### Development (Clean Slate)

```bash
# Stop containers
docker compose down

# Remove database volume
docker volume rm backend_db_data  # or appropriate volume name

# Restart (migrations auto-run)
docker compose up -d

# Verify
docker exec auto_tm_postgres psql -U auto_tm -d auto_tm -c '\dt'
```

### New Baseline Migration

1. Archive old migrations to `migrations_legacy/`
2. Create new `YYYYMMDD-baseline.js` with complete schema
3. Test fresh database creation
4. Document schema in this file

---

## Complete Database Reset Procedure

### Prerequisites

- Docker and Docker Compose installed
- Backend `.env` file configured

### Step 1: Stop Running Containers

```bash
cd /path/to/auto.tm-main/backend
docker compose down
```

### Step 2: Remove Database Volume

```bash
# Find the volume name
docker volume ls | grep auto

# Remove the volume (this deletes ALL data!)
docker volume rm backend_postgres_data
# or: docker volume rm auto_tm_postgres_data
```

### Step 3: Start Fresh Database

```bash
docker compose up -d
```

The entrypoint script will:
1. Wait for PostgreSQL to be ready
2. Run all migrations (now just the baseline migration)
3. Start the NestJS application

### Step 4: Verify Schema

```bash
# Connect to PostgreSQL
docker exec -it auto_tm_postgres psql -U auto_tm -d auto_tm

# List tables
\dt

# Check specific tables
\d users
\d otp_codes
```

### Expected Tables (Baseline Migration)

| Table | Purpose |
|-------|---------|
| `users` | User accounts (no otp column) |
| `otp_codes` | Unified OTP storage |
| `brands` | Car brands |
| `models` | Car models |
| `posts` | Car listings |
| `photo` | Photos |
| `video` | Videos |
| `file` | PDF files |
| `comments` | Post comments |
| `vlogs` | Video blogs |
| `banners` | Promotional banners |
| `categories` | Post categories |
| `subscriptions` | Subscription plans |
| `subscription_order` | Subscription orders |
| `notification_history` | Push notification logs |
| `convert_prices` | Currency conversion rates |
| `brands_user` | User brand subscriptions (junction) |
| `photo_posts` | Post photos (junction) |
| `photo_vlogs` | Vlog photos (junction) |

---

## Environment Variables

### Required

| Variable | Description | Default |
|----------|-------------|---------|
| `DATABASE_HOST` | PostgreSQL host | `db` (Docker), `localhost` (native) |
| `DATABASE_PORT` | PostgreSQL port | `5432` |
| `DATABASE_USERNAME` | Database username | Required |
| `DATABASE_PASSWORD` | Database password | Required |
| `DATABASE` | Database name | Required |
| `ACCESS_TOKEN_SECRET_KEY` | JWT access token secret | Required |
| `REFRESH_TOKEN_SECRET_KEY` | JWT refresh token secret | Required |

### OTP Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `OTP_TTL_SECONDS` | OTP expiration time | `300` (5 minutes) |
| `OTP_MAX_ATTEMPTS` | Max verification attempts | `5` |
| `TEST_OTP_NUMBERS` | Comma-separated test numbers | Empty |
| `TEST_OTP_PREFIX` | Prefix for deterministic test OTPs | `9936199999` |

### SMS Device Gateway

| Variable | Description | Default |
|----------|-------------|---------|
| `SMS_DEVICE_AUTH_TOKEN` | Auth token required from SMS device | Empty (no auth) |
| `SMS_DEFAULT_REGION` | Default SMS routing region | `tm` |
| `SMS_OTP_TEMPLATE` | OTP message template | `Alpha Motors: Your verification code is {code}...` |

**Note:** The SMS gateway runs on port 3091 with namespace `/sms`. Physical devices connect to this endpoint.

### Firebase

| Variable | Description | Default |
|----------|-------------|---------|
| `FIREBASE_PROJECT_ID` | Firebase project ID | Required for push |
| `FIREBASE_CLIENT_EMAIL` | Firebase service account email | Required for push |
| `FIREBASE_PRIVATE_KEY` | Firebase private key (escaped newlines) | Required for push |

---

## Migration Guide (From Previous Version)

If upgrading from the split OTP storage version:

1. **Backup existing data** (if needed)
2. **Drop database** (data will be lost)
3. **Run baseline migration** (creates clean schema)
4. **Users must re-register** (OTP verification creates accounts)

The new system:
- No email/password login (OTP-only)
- OTPs stored in `otp_codes` table with hashing, TTL, attempts
- SMS dispatch via socket to external microservice
- Test numbers return deterministic OTP `12345`

---

*Last updated: February 2026*

-->
