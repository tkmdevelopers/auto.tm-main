# Alpha Motors (auto.tm)

Full-stack automotive marketplace: **Flutter** mobile app (iOS/Android) and **NestJS** backend API with PostgreSQL. Users authenticate via phone OTP, create listings with photos/videos, comment, subscribe to premium features, and receive push notifications.

---

## Repository Layout

```
.
├── auto.tm-main/          # Flutter mobile app (Dart, GetX)
├── backend/               # NestJS API (TypeScript, Sequelize, PostgreSQL)
├── docs/                  # Cross-cutting documentation
│   ├── ARCHITECTURE_OVERVIEW.md   # Full-stack architecture
│   ├── ACCESS_MODEL.md           # Public vs token-required access (guest browse)
│   ├── ACCESS_MODEL_ROADMAP.md   # Roadmap + mobile app alignment audit
│   ├── HOME_SCREEN_ANALYSIS.md   # Home controller/screen analysis, init fix, phased improvements
│   ├── HOME_SCREEN_FLOW_AND_ANALYSIS.md   # Home flow, widget tree, dead code, image loading
│   ├── POST_DETAILS_SCREEN_ANALYSIS.md    # Post details flow, dead code, improvements
│   ├── TESTING.md                 # Manual & smoke testing
│   └── ROADMAP.md                 # Auth improvements & plans
├── CLAUDE.md              # AI/assistant rules for this repo
└── README.md              # This file (documentation index)
```

---

## Documentation Index

### Start here

| Document | Purpose |
|----------|---------|
| [docs/ARCHITECTURE_OVERVIEW.md](docs/ARCHITECTURE_OVERVIEW.md) | Full-stack overview: app, API, DB, auth flow, ports, where to find more |
| [backend/docs/DEVELOPMENT_SETUP.md](backend/docs/DEVELOPMENT_SETUP.md) | Backend local setup: Docker, env, seeding, migrations |
| [backend/docs/API_REFERENCE.md](backend/docs/API_REFERENCE.md) | Auth/OTP API contract (source of truth for endpoints and error codes) |

### Backend (NestJS)

| Document | Purpose |
|----------|---------|
| [backend/docs/DEVELOPMENT_SETUP.md](backend/docs/DEVELOPMENT_SETUP.md) | Dev workflow, Docker, native run, DB access, troubleshooting |
| [backend/docs/PRODUCTION_DEPLOYMENT.md](backend/docs/PRODUCTION_DEPLOYMENT.md) | Production deploy (air-gapped friendly), rollback, backups |
| [backend/docs/UPDATE_CHECKLIST.md](backend/docs/UPDATE_CHECKLIST.md) | Release checklists: code-only, migrations, seeds, rollback |
| [backend/docs/ARCHITECTURE.md](backend/docs/ARCHITECTURE.md) | Backend architecture: OTP/SMS flows, gateways, risks |
| [backend/docs/API_REFERENCE.md](backend/docs/API_REFERENCE.md) | Auth/OTP endpoints, error codes, rate limits, Flutter integration |
| [backend/docs/DATABASE.md](backend/docs/DATABASE.md) | Database schema summary, migrations, seeding |

### Cross-cutting

| Document | Purpose |
|----------|---------|
| [docs/ACCESS_MODEL.md](docs/ACCESS_MODEL.md) | **Public vs authenticated access:** guest browsing (no token), token required for post/comment/favorites; API matrix and diagrams |
| [docs/ACCESS_MODEL_ROADMAP.md](docs/ACCESS_MODEL_ROADMAP.md) | **Access model + TokenStore roadmap:** implementation phases, alignment audit of current mobile app, TokenStore verification checklist |
| [docs/TESTING.md](docs/TESTING.md) | Manual testing, deleted-user scenarios, smoke tests |
| [docs/ROADMAP.md](docs/ROADMAP.md) | Auth improvements plan, migration checklist, future work |

### Mobile (Flutter)

| Document | Purpose |
|----------|---------|
| [auto.tm-main/README.md](auto.tm-main/README.md) | Flutter app: env, run, build, project structure |
| [docs/HOME_SCREEN_ANALYSIS.md](docs/HOME_SCREEN_ANALYSIS.md) | Home controller/screen analysis, init fix, phased improvements (Phase A–D) |
| [docs/HOME_SCREEN_FLOW_AND_ANALYSIS.md](docs/HOME_SCREEN_FLOW_AND_ANALYSIS.md) | Home flow, widget tree, dead code, image loading (§10) |
| [docs/POST_DETAILS_SCREEN_ANALYSIS.md](docs/POST_DETAILS_SCREEN_ANALYSIS.md) | Post details flow, data flow, dead code, improvements |

---

## Quick start

**Backend (from `backend/`):**

```bash
cp .env.example .env
docker compose -f docker-compose.build.yml build
docker compose up -d
# Seed: export DATABASE_HOST=localhost DATABASE_PORT=5432 ... && npm run db:seed:all
```

**API:** http://localhost:3080 — **Swagger:** http://localhost:3080/api-docs

**Flutter (from `auto.tm-main/`):**

```bash
# Set API_BASE in .env (e.g. http://10.0.2.2:3080 for Android emulator)
flutter pub get
flutter run
```

---

## Key pointers

- Backend entry: [backend/src/main.ts](backend/src/main.ts)
- Docker dev: [backend/docker-compose.yml](backend/docker-compose.yml)
- Docker prod: [backend/docker-compose.prod.yml](backend/docker-compose.prod.yml)
- Migrations: [backend/migrations/](backend/migrations/)
- Seeds: [backend/scripts/](backend/scripts/), [backend/dumpCurrencies.js](backend/dumpCurrencies.js), [backend/dumpCarBrands.js](backend/dumpCarBrands.js)
