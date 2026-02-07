# Gemini CLI Agent Guide

This file provides context and guidance for the Gemini CLI agent when working with this repository.

## Project Overview

**Alpha Motors (auto.tm)** is a full-stack automotive marketplace.
- **Frontend:** Flutter mobile app (iOS/Android) using GetX.
- **Backend:** NestJS API with PostgreSQL and Sequelize.
- **Key Features:** User authentication via phone OTP (Physical SMS Gateway), car listings with photos/videos, comments, favorites, subscriptions, and push notifications.

## Repository Layout

```
.
├── gemini.md              # This file (AI assistant guide)
├── README.md              # Documentation index
├── backend/               # NestJS API (TypeScript, Sequelize, PostgreSQL)
│   ├── src/               # Source code (feature modules)
│   ├── migrations/        # Sequelize migrations
│   ├── scripts/           # Seed scripts
│   ├── docker/            # Entrypoint scripts
│   ├── uploads/           # Media storage
│   └── docs/              # Backend documentation
└── auto.tm-main/          # Flutter mobile app (Dart, GetX)
    ├── lib/               # Dart source
    ├── assets/            # Images, fonts, JSON
    └── .env               # API_BASE config
```

## Access Model

| Access | What | Examples |
|--------|------|----------|
| **Public** | Browse & discover | List/filter posts, view post details, brands, categories, banners, comments, vlogs, OTP send/verify |
| **Token Required** | Create & interact | Post listing, comment, favorites, brand subscribe, profile, auth/me, refresh, logout |

**Rule:** Read-only catalog endpoints = public. Create/modify user data = token required.

## Commands

### Backend Commands
Run from `backend/`:

```bash
# Development
npm run start:dev          # Dev server with hot-reload (port 3080)
npm run lint               # ESLint with auto-fix
npm run format             # Prettier formatting
npm run test               # Jest unit tests (*.spec.ts files)

# Database
npm run db:migrate         # Run Sequelize migrations
npm run db:migrate:undo    # Undo last migration
npm run db:seed:all        # Seed database (currencies, brands, etc.)

# Docker
docker compose up -d       # Start API + PostgreSQL (dev)
docker compose -f docker-compose.build.yml build api
```

### Flutter Commands
Run from `auto.tm-main/`:

```bash
flutter pub get             # Install dependencies
flutter run                 # Run on connected device/emulator
flutter analyze             # Dart linter
flutter test                # Unit tests
flutter build apk --release # Android APK
flutter build ios --release # iOS build (macOS only)
```

## Architecture

### Backend (NestJS)
**Modular Architecture:** `src/{feature}/` containing controller, service, entity, dto, and module.

**Runtime Topology:**
- **HTTP API:** Port `3080` (`/api/v1/...`). Swagger at `/api-docs`.
- **Client Socket.IO:** Port `3090` (Chat/Notifications).
- **SMS Gateway Socket.IO:** Port `3091` (`/sms` namespace). Connects to a physical Android device to send OTPs.
- **Database:** PostgreSQL on port `5432`.

**Key Modules:**
- **Auth:** JWT access (15m) + Refresh (7d) with rotation.
- **OTP:** `POST /otp/send` -> `POST /otp/verify`.
- **Photo/Video:** Uses Sharp and FFmpeg. stored in `uploads/`.

### Frontend (Flutter + GetX)
**State Management:** GetX (`Rx<T>`, `Obx()`, `GetxController`).
**Networking:** Dio with interceptors for JWT injection and refresh.
**Structure:**
- `lib/screens/`: UI features.
- `lib/services/`: Logic (Auth, API, Tokens).
- `lib/global_controllers/`: App-wide state (Theme, Language).

## Authentication Flow

1.  **Send OTP:** `POST /api/v1/otp/send` -> Backend hashes OTP, sends via SMS Gateway (Port 3091).
2.  **Verify OTP:** `POST /api/v1/otp/verify` -> Returns Access + Refresh tokens.
3.  **Refresh:** `POST /api/v1/auth/refresh` -> Rotates tokens.
4.  **Handling 401:** Client interceptor catches 401. If `USER_DELETED`, forces logout. If expired, attempts refresh.

## Key Conventions

- **API Responses:** `{ message: string, data: any, status: boolean }`
- **IDs:** UUIDs used for primary keys.
- **File Uploads:** `multipart/form-data`.
- **Environment:**
    - Backend: `.env` (needs `DATABASE_HOST`, `JWT_SECRETS`, etc.).
    - Flutter: `.env` (needs `API_BASE`).

## Useful Documentation References

- **Backend Architecture & Risks:** [backend/docs/ARCHITECTURE.md](backend/docs/ARCHITECTURE.md)
- **API Reference:** [backend/docs/API_REFERENCE.md](backend/docs/API_REFERENCE.md)
- **Database Schema:** [backend/docs/DATABASE.md](backend/docs/DATABASE.md)
- **Deployment:** [backend/docs/PRODUCTION_DEPLOYMENT.md](backend/docs/PRODUCTION_DEPLOYMENT.md)
