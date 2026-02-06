# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Alpha Motors (auto.tm) — a full-stack automotive marketplace. **Flutter mobile app** (iOS/Android) + **NestJS backend** API with PostgreSQL. Users buy/sell cars via phone OTP authentication, create listings with photos/videos, comment, subscribe to premium features, and receive push notifications.

## Repository Layout

```
auto.tm-main/
├── backend/          # NestJS API (TypeScript, Sequelize, PostgreSQL)
└── auto.tm-main/     # Flutter mobile app (Dart, GetX)
```

## Backend Commands

All commands run from `backend/`:

```bash
npm run start:dev          # Dev server with hot-reload (port 3080)
npm run build              # Compile TypeScript
npm run start:prod         # Run compiled output (dist/main)
npm run lint               # ESLint with auto-fix
npm run format             # Prettier formatting
npm run test               # Jest unit tests (*.spec.ts files)
npm run test:watch         # Jest in watch mode
npm run test:e2e           # E2E tests (test/jest-e2e.json config)
npm run test:cov           # Test coverage report
npm run db:migrate         # Run Sequelize migrations
npm run db:migrate:undo    # Undo last migration
```

### Docker (full stack with PostgreSQL)

```bash
docker compose up -d                                    # Dev: start API + PostgreSQL
docker compose -f docker-compose.build.yml build api    # Build production image
docker compose -f docker-compose.prod.yml up -d         # Production deployment
```

## Flutter Commands

All commands run from `auto.tm-main/`:

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

Feature-based modular architecture. Each feature is a self-contained NestJS module with its own controller, service, entity, and DTO files:

```
src/{feature}/
├── {feature}.controller.ts   # HTTP routes
├── {feature}.service.ts      # Business logic
├── {feature}.entity.ts       # Sequelize model
├── {feature}.dto.ts          # Request/response DTOs
└── {feature}.module.ts       # NestJS module wiring
```

**Key modules**: `auth`, `otp`, `post`, `photo`, `video`, `comments`, `brands`, `models`, `categories`, `colors`, `banners`, `subscription`, `notification`, `vlog`, `admins`, `chat`, `file`, `mail`

**Entry point**: `src/main.ts` — sets up Swagger at `/api-docs`, global prefix `/api`, URI versioning (`/api/v1/...`), CORS (all origins), static file serving at `/media`.

**Database**: PostgreSQL 16 via Sequelize ORM with `sequelize-typescript` decorators. Migrations in `backend/migrations/` (timestamped, run automatically via Docker entrypoint). Config generated at runtime from env vars in `docker/entrypoint.sh`.

**Auth flow**: Phone OTP → JWT (access 15min + refresh 7d). Guards in `src/guards/` (`AuthGuard`, `AdminGuard`, `RefreshGuard`). Passport strategies in `src/strategy/`. Test phone numbers return deterministic OTP `12345`.

**Junction tables**: Many-to-many relationships defined in `src/junction/` (photo_posts, photo_vlog, brands_user).

**WebSockets**: `src/chat/chat.gateway.ts` uses Socket.io for real-time chat/notifications; OTP SMS device gateway is `src/sms/sms.gateway.ts` (port 3091).

**File processing**: Sharp for image compression, Fluent-FFmpeg for video processing. Uploads stored in `uploads/` directory, served at `/media`.

### Frontend (Flutter + GetX)

Screen-based structure with GetX reactive state management:

```
lib/
├── main.dart                    # Entry point, permissions, Firebase init
├── app.dart                     # Auth check → routes to login or home
├── screens/{feature}/           # UI screens with their controllers
├── services/                    # Auth, token, notification services
├── global_controllers/          # App-wide state (theme, connection, currency, language)
├── utils/                       # Themes, translations, API base URL (key.dart)
├── ui_components/               # Shared color palette
├── global_widgets/              # Reusable widgets
└── navbar/                      # Bottom navigation
```

**State management**: GetX (`Rx<T>` observables + `Obx()` widget rebuilds). `GetxController` for screen-level state, `GetxService` for app-wide services (auth, notifications).

**Routing**: GetX named routes defined in `main.dart`. Key routes: `/` (auth check), `/navView` (main app with bottom nav), `/register`, `/checkOtp`, `/home`, `/profile`, `/filter`, `/search`.

**API base URL**: Loaded from `.env` file via `flutter_dotenv`. Android emulator uses `10.0.2.2:3080`, iOS simulator uses `localhost:3080`.

**i18n**: GetX Translations in `utils/translation.dart`. Supports English, Russian, and Turkmen locales.

## Environment Setup

**Backend** `.env` (copy from `.env.example`): Database credentials, JWT secrets, Firebase keys, email config. `DATABASE_HOST=db` for Docker, `localhost` for native.

**Flutter** `.env`: Single `API_BASE` variable pointing to the backend URL.

## Key Conventions

- Backend API responses use `{ message, data, status }` shape
- File uploads via multipart form-data (Multer)
- All backend entities use UUID primary keys
- ESLint config (flat config format in `eslint.config.mjs`) allows `any` types (`@typescript-eslint/no-explicit-any` disabled)
- Swagger/OpenAPI docs auto-generated from decorators, available at `/api-docs`
- Docker entrypoint waits for PostgreSQL readiness before running migrations and starting the app
