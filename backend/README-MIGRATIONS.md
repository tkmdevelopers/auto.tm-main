# Database Migrations Guide

## Overview

Database migrations are managed using Sequelize CLI. The configuration is automatically generated from environment variables in your `.env` file.

## Setup

### 1. Configure Environment Variables

Create a `.env` file in the `backend/` directory (or copy from `.env.example`):

```bash
# Database Configuration
DATABASE_HOST=localhost          # Use 'db' for Docker, 'localhost' for local dev
DATABASE_PORT=5432
DATABASE_USERNAME=postgres       # Your PostgreSQL username
DATABASE_PASSWORD=your_password  # Your PostgreSQL password
DATABASE=alpha_motors            # Database name
```

### 2. Generate Config

The `config/config.json` file is automatically generated from your `.env` file when you run migration commands. You can also generate it manually:

```bash
npm run config:generate
```

## Running Migrations

### Check Migration Status

```bash
npm run db:migrate:status
```

### Run Pending Migrations

```bash
npm run db:migrate
```

This will:
1. Automatically generate `config/config.json` from your `.env` file
2. Run all pending migrations (including the baseline migration)

### Undo Last Migration

```bash
npm run db:migrate:undo
```

### Undo All Migrations

```bash
npm run db:migrate:undo:all
```

## Environment-Specific Configuration

### Development (Local)

```bash
# .env for local development
DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_USERNAME=postgres
DATABASE_PASSWORD=your_local_password
DATABASE=alpha_motors
```

### Production (Docker)

```bash
# .env for Docker/production
DATABASE_HOST=db
DATABASE_PORT=5432
DATABASE_USERNAME=auto_tm
DATABASE_PASSWORD=your_secure_password
DATABASE=auto_tm
```

The migration scripts automatically use the correct environment based on your `.env` file.

## Docker Integration

When using Docker, migrations run automatically via `docker/entrypoint.sh` when the container starts. The entrypoint script:

1. Waits for PostgreSQL to be ready
2. Regenerates `config/config.json` from environment variables
3. Runs `sequelize-cli db:migrate`
4. Starts the application

## Troubleshooting

### Password Authentication Failed

If you get a password authentication error:

1. **Check your `.env` file** - Make sure `DATABASE_PASSWORD` is set correctly
2. **Verify PostgreSQL is running** - `pg_isready -h localhost -p 5432`
3. **Check database credentials** - Ensure the username/password match your PostgreSQL setup
4. **Regenerate config** - Run `npm run config:generate` to refresh the config

### Config Not Updating

If `config/config.json` doesn't reflect your `.env` changes:

```bash
# Manually regenerate config
npm run config:generate

# Then check the generated file
cat config/config.json
```

### Migration Already Run

If a migration was already run and you need to reset:

```bash
# Undo all migrations (WARNING: This will drop all tables)
npm run db:migrate:undo:all

# Then run migrations again
npm run db:migrate
```

## Migration Files

- **Baseline Migration**: `migrations/20260202000000-baseline.js`
  - Creates all tables from scratch
  - Safe to run on fresh databases
  - Checks for existing tables before creating

## Notes

- The `config/config.json` file is auto-generated and should not be manually edited
- Always use environment variables in `.env` for database configuration
- Never commit `.env` files to version control (already in `.gitignore`)
