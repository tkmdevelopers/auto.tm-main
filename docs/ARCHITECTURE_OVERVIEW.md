# Alpha Motors — Architecture Overview

This document describes the full-stack architecture of Alpha Motors (auto.tm): mobile app, backend API, database, and how they work together. For backend-only details and runbooks, see [backend/docs/](backend/docs/).

---

## 1. System Context

| Layer | Technology | Purpose |
|-------|------------|---------|
| **Mobile** | Flutter (Dart), GetX | iOS/Android app: listings, OTP login, posts, favorites, profile, push |
| **API** | NestJS (TypeScript) | REST API + Socket.IO gateways |
| **Database** | PostgreSQL 16 | Persistence via Sequelize ORM |
| **Media** | Disk (Docker volume) | Photos/videos under `uploads/`, served at `/media` |
| **Real-time** | Socket.IO | Client events (port 3090), SMS device gateway (3091) |

---

## 2. Repository Layout

```
auto.tm-main/
├── backend/                 # NestJS API
│   ├── src/                  # TypeScript source
│   │   ├── main.ts           # Entry: Swagger, CORS, /api, versioning, /media
│   │   ├── {feature}/        # Per-feature modules (auth, otp, post, photo, …)
│   │   ├── guards/           # AuthGuard, AdminGuard, RefreshGuard
│   │   ├── strategy/         # JWT Passport strategies
│   │   ├── junction/         # M2M: brands_user, photo_posts, photo_vlog
│   │   └── database/        # Sequelize config
│   ├── migrations/          # Sequelize migrations (run on container start)
│   ├── scripts/             # Seed scripts, build-release
│   ├── docker/              # Entrypoint (wait for DB, migrate, start)
│   └── docs/                # Backend runbooks and API reference
├── auto.tm-main/            # Flutter app
│   ├── lib/
│   │   ├── main.dart        # Entry, Firebase, GetX routes
│   │   ├── app.dart        # Auth check → /navView or /register
│   │   ├── screens/        # Feature screens + controllers
│   │   ├── services/       # Auth, ApiClient, TokenStore, notifications
│   │   ├── global_controllers/
│   │   ├── utils/          # Themes, translation, API base URL
│   │   └── navbar/
│   └── .env                 # API_BASE (e.g. http://10.0.2.2:3080)
├── docs/                    # Cross-cutting docs (this file, testing, roadmap)
├── CLAUDE.md                # AI/assistant rules for this repo
└── README.md                # Documentation index
```

---

## 3. Runtime Topology

| Component | Port / Path | Notes |
|-----------|-------------|--------|
| HTTP API | `3080` | Global prefix `/api`, URI versioning `/api/v1/...` |
| Swagger | `http://localhost:3080/api-docs` | OpenAPI UI |
| Static media | `/media` | Serves `uploads/` (photos, videos) |
| Client Socket.IO | `3090` | Chat/notifications, phone↔socket mapping |
| SMS device Socket.IO | `3091`, namespace `/sms` | Physical Android device for OTP SMS |
| PostgreSQL | `5432` | Service name `db` in Docker |

---

## 4. Backend Modules (NestJS)

Feature-based modules; each has controller, service, entity, DTOs, module.

| Module | Responsibility |
|--------|----------------|
| **auth** | JWT refresh rotation, `/auth/me`, `/auth/refresh`, `/auth/logout`, profile update, avatar, Firebase token |
| **otp** | `POST /otp/send`, `POST /otp/verify`; OTP in `otp_codes` table; test numbers → deterministic code |
| **sms** | Socket.IO gateway for physical SMS device; dispatches OTP SMS |
| **post** | Car listings (CRUD), filters, relation to photos/videos |
| **photo** | Photo upload (Sharp), junction `photo_posts`, `photo_vlog` |
| **video** | Video processing (Fluent-FFmpeg) |
| **comments** | Comments on posts |
| **brands** / **models** | Car brands and models (seeded) |
| **categories** / **colors** / **banners** | Reference data and UI content |
| **subscription** | Premium subscriptions, orders |
| **notification** | Push notification history |
| **vlog** | Vlog entries with photo association |
| **admins** | Admin-only endpoints |
| **chat** | Client Socket.IO gateway (3090) |
| **file** | File upload utilities |
| **mail** | Email service |

Guards: `AuthGuard` (JWT + user existence, emits `USER_DELETED`), `AdminGuard`, `RefreshGuard`. Passport: `AccessToken.strategy`, `RefreshToken.strategy`.

---

## 5. Authentication Flow

- **No email/password.** Phone OTP only.
- **Send OTP:** `POST /api/v1/otp/send` → OTP stored in `otp_codes`, SMS sent (or test code returned).
- **Verify OTP:** `POST /api/v1/otp/verify` → Access token (15 min) + refresh token (7 days); user created if new.
- **Refresh:** `POST /api/v1/auth/refresh` with refresh token → new access + new refresh; old refresh invalidated (rotation). Reuse → `TOKEN_REUSE`, session revoked.
- **Deleted user:** Every authenticated request checks user existence; if missing → `401 USER_DELETED`; client must log out and clear tokens.

Token storage (Flutter): `TokenStore` (flutter_secure_storage). All API calls go through `ApiClient` (Dio) which attaches access token, handles `TOKEN_EXPIRED` (refresh + retry), and `USER_DELETED` (force logout). Boot: `app.dart` calls `GET /auth/me` to validate session.

See [backend/docs/API_REFERENCE.md](backend/docs/API_REFERENCE.md) for full contract and [backend/docs/ARCHITECTURE.md](backend/docs/ARCHITECTURE.md) for OTP/SMS details.

---

## 6. Database (PostgreSQL)

- **ORM:** Sequelize with `sequelize-typescript` decorators.
- **Migrations:** `backend/migrations/` (timestamped); run automatically on container start via `docker/entrypoint.sh`.
- **Config:** From env (e.g. `DATABASE_HOST`, `DATABASE_PASSWORD`); see [backend/docs/DEVELOPMENT_SETUP.md](backend/docs/DEVELOPMENT_SETUP.md).

**Core tables:** `users`, `otp_codes`, `brands`, `models`, `posts`, `photo`, `video`, `comments`, `banners`, `categories`, `subscriptions`, `subscription_order`, `vlogs`, `notification_history`, `convert_prices`, `file`. **Junction:** `brands_user`, `photo_posts`, `photo_vlog`.

Detailed schema and migrations: [backend/docs/DATABASE.md](backend/docs/DATABASE.md).

---

## 7. Flutter App (High Level)

- **State:** GetX (`GetxController`, `Obx`, reactive).
- **Routing:** Named routes in `main.dart`; auth gate in `app.dart` (`/` → auth check → `/navView` or `/register`).
- **API:** Single `ApiClient` (Dio + interceptors); base URL from `.env` (`API_BASE`). Android emulator: `10.0.2.2:3080`, iOS simulator: `localhost:3080`.
- **i18n:** GetX translations (e.g. English, Russian, Turkmen).

See [auto.tm-main/README.md](auto.tm-main/README.md) for setup and structure.

---

## 8. Where to Find More

| Topic | Document |
|-------|----------|
| Backend dev setup, Docker, seeding | [backend/docs/DEVELOPMENT_SETUP.md](backend/docs/DEVELOPMENT_SETUP.md) |
| Production deploy, rollback, backups | [backend/docs/PRODUCTION_DEPLOYMENT.md](backend/docs/PRODUCTION_DEPLOYMENT.md) |
| Release/update checklists | [backend/docs/UPDATE_CHECKLIST.md](backend/docs/UPDATE_CHECKLIST.md) |
| Backend architecture, OTP/SMS flows, risks | [backend/docs/ARCHITECTURE.md](backend/docs/ARCHITECTURE.md) |
| Auth/OTP API contract (source of truth) | [backend/docs/API_REFERENCE.md](backend/docs/API_REFERENCE.md) |
| Database schema and migrations | [backend/docs/DATABASE.md](backend/docs/DATABASE.md) |
| Manual and smoke testing | [docs/TESTING.md](TESTING.md) |
| Auth improvements and roadmap | [docs/ROADMAP.md](ROADMAP.md) |
