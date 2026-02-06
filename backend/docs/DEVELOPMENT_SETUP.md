# Development Setup Guide

Complete guide for setting up the Alpha Motors backend for local development.

## Prerequisites

- **Docker Desktop** (with Docker Compose v2)
- **Node.js 20+** (for running scripts outside Docker)
- **Git** configured with your credentials

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

---

## Quick Start (Recommended)

### 1. Clone and Navigate

```bash
cd /path/to/auto.tm-main/backend
```

### 2. Environment Setup

```bash
# Copy example environment file
cp .env.example .env

# Edit if needed (defaults work for local dev)
nano .env
```

**Key variables for development:**
| Variable | Default | Description |
|----------|---------|-------------|
| `DATABASE_HOST` | `db` | Docker service name (or `localhost` if running natively) |
| `DATABASE_PORT` | `5432` | Postgres port |
| `DATABASE_PASSWORD` | `Key_bismynick1` | Local dev password |
| `PORT` | `3080` | API port |

### 3. Build and Start

```bash
# Build the Docker image (first time or after code changes)
docker compose -f docker-compose.build.yml build

# Start PostgreSQL + API
docker compose up -d
```

### 4. Seed Database

The database starts empty. Seed essential data:

```bash
# Set environment for local scripts
export DATABASE_HOST=localhost
export DATABASE_PORT=5432
export DATABASE_USERNAME=auto_tm
export DATABASE_PASSWORD=Key_bismynick1
export DATABASE=auto_tm

# Seed currencies and car brands/models
npm run db:seed:all
```

**Expected output:**
```
✓ TMT: 1 TMT - Turkmenistan Manat
✓ USD: 19.5 TMT - US Dollar
✓ CNY: 2.7 TMT - Chinese Yuan
✓ Brands: 131
✓ Models: 2447
```

### 5. Verify

```bash
# Check API is running
curl http://localhost:3080/api-docs

# View logs
docker logs alpha_backend --tail 50
```

**API Documentation:** http://localhost:3080/api-docs

---

## Development Workflow

### After Code Changes

```bash
# Rebuild and restart (preserves database)
docker compose -f docker-compose.build.yml build
docker compose up -d
```

### Fresh Database (Nuclear Option)

⚠️ **This deletes all data!**

```bash
# Stop and remove containers + volumes
docker compose down -v

# Rebuild and start fresh
docker compose -f docker-compose.build.yml build
docker compose up -d

# Re-seed required data
npm run db:seed:all
```

### View Logs

```bash
# API logs (follow mode)
docker logs -f alpha_backend

# Postgres logs
docker logs -f auto_tm_postgres
```

### Database Access

```bash
# Connect to Postgres CLI
docker exec -it auto_tm_postgres psql -U auto_tm -d auto_tm

# Common queries
\dt                          # List tables
\d+ posts                    # Describe posts table
SELECT COUNT(*) FROM brands; # Count brands
\q                           # Exit
```

---

## Running Native (Without Docker for API)

For faster hot-reload during development:

### 1. Start Only Postgres in Docker

```bash
docker compose up db -d
```

### 2. Run API Natively

```bash
# Install dependencies
npm install

# Set environment
export DATABASE_HOST=localhost
export DATABASE_PORT=5432
export DATABASE_USERNAME=auto_tm
export DATABASE_PASSWORD=Key_bismynick1
export DATABASE=auto_tm

# Run migrations
npm run db:migrate

# Start with hot-reload
npm run start:dev
```

---

## Database Management

### Run Migrations

```bash
# Check migration status
npm run db:migrate:status

# Run pending migrations
npm run db:migrate

# Undo last migration
npm run db:migrate:undo

# Undo all migrations (DANGEROUS)
npm run db:migrate:undo:all
```

### Seeding Scripts

| Script | Command | Description |
|--------|---------|-------------|
| All seeds | `npm run db:seed:all` | Currencies + Brands/Models |
| Currencies only | `npm run db:seed:currencies` | TMT, USD, CNY rates |
| Brands only | `npm run db:seed:brands` | 131 brands, 2447 models |
| Demo posts | `npm run db:seed:demo-posts` | ~300 posts with images (requires API running) |

### Manual Seeding (when scripts fail)

```bash
export DATABASE_HOST=localhost DATABASE_PORT=5432 DATABASE_USERNAME=auto_tm DATABASE_PASSWORD=Key_bismynick1 DATABASE=auto_tm

node dumpCurrencies.js
node dumpCarBrands.js
```

---

## Troubleshooting

### Error: `relation "xxx" does not exist`

**Cause:** Migrations haven't run.

**Fix:**
```bash
# Check container logs for migration errors
docker logs alpha_backend | grep -i migration

# Or run migrations manually
docker exec alpha_backend node_modules/.bin/sequelize-cli db:migrate
```

### Error: `FK constraint violation`

**Cause:** Missing seed data (brands, currencies, etc.)

**Fix:**
```bash
npm run db:seed:all
```

### Error: `port 5432 already in use`

**Cause:** Local Postgres running on same port.

**Fix:**
```bash
# Option 1: Stop local Postgres
brew services stop postgresql  # macOS

# Option 2: Use different port
DATABASE_PORT=5433 docker compose up -d
```

### Error: `ECONNREFUSED` when seeding

**Cause:** Scripts can't reach Postgres.

**Fix:**
```bash
# Ensure DATABASE_HOST=localhost for local scripts
export DATABASE_HOST=localhost
npm run db:seed:all
```

### API Returns 500 Errors

```bash
# Check detailed logs
docker logs alpha_backend --tail 100

# Common issues:
# - Missing environment variables
# - Database schema mismatch
# - Entity/migration mismatch
```

---

## Useful Commands Reference

```bash
# ─────────────────────────────────────────────
# Docker Compose
# ─────────────────────────────────────────────
docker compose up -d                              # Start all services
docker compose down                               # Stop all services
docker compose down -v                            # Stop + delete volumes (RESETS DB)
docker compose -f docker-compose.build.yml build  # Rebuild image

# ─────────────────────────────────────────────
# Container Management
# ─────────────────────────────────────────────
docker ps                                         # List running containers
docker logs -f alpha_backend                      # Follow API logs
docker exec -it alpha_backend sh                  # Shell into API container
docker exec -it auto_tm_postgres psql -U auto_tm  # Postgres CLI

# ─────────────────────────────────────────────
# Database
# ─────────────────────────────────────────────
npm run db:migrate                                # Run migrations
npm run db:migrate:status                         # Check migration status
npm run db:seed:all                               # Seed all base data

# ─────────────────────────────────────────────
# Development
# ─────────────────────────────────────────────
npm run start:dev                                 # Hot-reload dev server
npm run lint                                      # ESLint
npm run format                                    # Prettier
npm run test                                      # Unit tests
```

---

## Architecture Reference

```
backend/
├── src/                      # TypeScript source
│   ├── main.ts               # Entry point
│   ├── {feature}/            # Feature modules
│   ├── guards/               # Auth guards
│   ├── strategy/             # Passport strategies
│   └── junction/             # M2M junction tables
├── migrations/               # Sequelize migrations
├── scripts/                  # Utility scripts
├── docker/                   # Docker entrypoint
├── docker-compose.yml        # Dev compose file
├── docker-compose.build.yml  # Build compose file
├── Dockerfile                # Multi-stage build
└── .env                      # Environment config
```
