# Alpha Motors — Backend (NestJS)

This folder contains the NestJS API (Sequelize + PostgreSQL) for Alpha Motors.

## Documentation

- Backend development setup (Docker/native + seeding): [docs/DEVELOPMENT_SETUP.md](docs/DEVELOPMENT_SETUP.md)
- Production deployment (air-gapped friendly): [docs/PRODUCTION_DEPLOYMENT.md](docs/PRODUCTION_DEPLOYMENT.md)
- Update/runbook checklists: [docs/UPDATE_CHECKLIST.md](docs/UPDATE_CHECKLIST.md)
- Backend architecture (flows + known risks): [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- Auth/OTP API reference (source of truth for endpoints): [docs/API_REFERENCE.md](docs/API_REFERENCE.md)

## Common Commands

Run from this directory:

```bash
# Start API + Postgres (dev compose)
docker compose up -d

# Build the backend image (prod build)
docker compose -f docker-compose.build.yml build

# Native dev server (requires local Node deps)
npm run start:dev
```

## Ports

- `3080` HTTP API (Swagger at `/api-docs`)
- `3090` Socket.IO gateway (client real-time)
- `3091` Socket.IO gateway (`/sms` namespace, physical SMS device)

## Notes

- For NestJS framework docs, see https://docs.nestjs.com/

- Canonical runbooks live in [docs/](docs/) (don’t duplicate deployment steps here).
