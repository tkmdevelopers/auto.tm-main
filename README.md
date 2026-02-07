# Alpha Motors (auto.tm)

Full-stack automotive marketplace: **Flutter** mobile app (iOS/Android) and **NestJS** backend API with PostgreSQL. Users authenticate via phone OTP, create listings with photos/videos, comment, subscribe to premium features, and receive push notifications.

---c

## Repository Layout

```
.
├── CLAUDE.md              # AI assistant guide (project overview, commands, architecture)
├── README.md              # This file (documentation index)
├── backend/               # NestJS API (TypeScript, Sequelize, PostgreSQL)
│   ├── src/               # Source code
│   ├── migrations/        # Database migrations
│   ├── docs/              # Backend documentation
│   └── docker-compose.yml # Dev environment
└── auto.tm-main/          # Flutter mobile app (Dart, GetX)
    ├── lib/               # Dart source
    └── README.md          # Flutter-specific docs
```

---

## Documentation

### AI Assistant

| Document | Purpose |
|----------|---------|
| [gemini.md](gemini.md) | Complete project guide for AI assistants — architecture, commands, access model, modules |

### Backend

| Document | Purpose |
|----------|---------|
| [backend/docs/DEVELOPMENT_SETUP.md](backend/docs/DEVELOPMENT_SETUP.md) | Local dev, Docker, seeding, troubleshooting |
| [backend/docs/PRODUCTION_DEPLOYMENT.md](backend/docs/PRODUCTION_DEPLOYMENT.md) | Production deploy, rollback, backups |
| [backend/docs/UPDATE_CHECKLIST.md](backend/docs/UPDATE_CHECKLIST.md) | Release checklists |
| [backend/docs/ARCHITECTURE.md](backend/docs/ARCHITECTURE.md) | OTP/SMS flows, known risks |
| [backend/docs/API_REFERENCE.md](backend/docs/API_REFERENCE.md) | Auth/OTP API contract |
| [backend/docs/DATABASE.md](backend/docs/DATABASE.md) | Schema, migrations |

### Flutter

| Document | Purpose |
|----------|---------|
| [auto.tm-main/README.md](auto.tm-main/README.md) | Flutter app setup, commands, structure |

---

## Quick Start

**Backend (from `backend/`):**

```bash
cp .env.example .env
docker compose up -d
```

**API:** http://localhost:3080 — **Swagger:** http://localhost:3080/api-docs

**Flutter (from `auto.tm-main/`):**

```bash
flutter pub get
flutter run
```

---

## Key Pointers

- Backend entry: [backend/src/main.ts](backend/src/main.ts)
- Docker dev: [backend/docker-compose.yml](backend/docker-compose.yml)
- Migrations: [backend/migrations/](backend/migrations/)
