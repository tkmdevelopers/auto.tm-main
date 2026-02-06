# Alpha Motors (auto.tm)

Full-stack automotive marketplace:
- **Mobile app**: Flutter (iOS/Android) in [auto.tm-main/](auto.tm-main/)
- **Backend API**: NestJS + Sequelize + PostgreSQL in [backend/](backend/)

## Start Here

- Backend development setup: [backend/docs/DEVELOPMENT_SETUP.md](backend/docs/DEVELOPMENT_SETUP.md)
- Production deployment (air-gapped friendly): [backend/docs/PRODUCTION_DEPLOYMENT.md](backend/docs/PRODUCTION_DEPLOYMENT.md)
- Release/update checklist: [backend/docs/UPDATE_CHECKLIST.md](backend/docs/UPDATE_CHECKLIST.md)
- Auth/OTP API contract (source of truth): [backend/docs/API_REFERENCE.md](backend/docs/API_REFERENCE.md)
- Backend architecture (detailed, includes OTP flow + risks): [backend/docs/ARCHITECTURE.md](backend/docs/ARCHITECTURE.md)

## Repository Layout

```
.
├── auto.tm-main/            # Flutter mobile app
├── backend/                 # NestJS API + Sequelize migrations + Docker
├── assets/                  # UI assets (Flutter)
├── CLAUDE.md                # Assistant/dev notes for this repo
└── README.md                # This file (documentation index)
```

## Where To Find What

### Backend

- Local dev workflow, Docker, seeding: [backend/docs/DEVELOPMENT_SETUP.md](backend/docs/DEVELOPMENT_SETUP.md)
- Production deploy, rollback, backups: [backend/docs/PRODUCTION_DEPLOYMENT.md](backend/docs/PRODUCTION_DEPLOYMENT.md)
- Operational checklists (updates, seeding changes): [backend/docs/UPDATE_CHECKLIST.md](backend/docs/UPDATE_CHECKLIST.md)
- Architecture and system flows: [backend/docs/ARCHITECTURE.md](backend/docs/ARCHITECTURE.md)

### API Contract

- Auth/OTP endpoints and semantics: [backend/docs/API_REFERENCE.md](backend/docs/API_REFERENCE.md)
- Interactive Swagger docs (when running): `http://localhost:3080/api-docs`

### Mobile (Flutter)

- Flutter app sources: [auto.tm-main/](auto.tm-main/)
- If you need Flutter environment/build notes, add them to [auto.tm-main/README.md](auto.tm-main/README.md).

## Quick Pointers

- Backend entry point: [backend/src/main.ts](backend/src/main.ts)
- Docker compose (dev): [backend/docker-compose.yml](backend/docker-compose.yml)
- Docker compose (prod): [backend/docker-compose.prod.yml](backend/docker-compose.prod.yml)
- Migrations: [backend/migrations/](backend/migrations/)
- Seed scripts: [backend/scripts/](backend/scripts/) and [backend/dumpCurrencies.js](backend/dumpCurrencies.js), [backend/dumpCarBrands.js](backend/dumpCarBrands.js)
