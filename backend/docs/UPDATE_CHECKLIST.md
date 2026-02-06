# Update & Release Checklist

Quick reference checklists for common update scenarios.

---

## 🔄 Code-Only Update (No Database Changes)

For bug fixes and feature changes that don't modify database schema.

### Development Machine

```bash
# 1. Commit all changes
git add -A
git commit -m "Fix: description of changes"

# 2. Bump version
nano package.json  # Update "version": "0.X.Y"

# 3. Build release
cd backend
./scripts/build-release.sh

# 4. Transfer to server
scp -r release/alpha-motors-vX.X.X user@server:/opt/alpha-motors/
```

### Production Server

```bash
# 1. Navigate to new version
cd /opt/alpha-motors/alpha-motors-vX.X.X

# 2. Copy existing .env
cp ../alpha-motors-vPREVIOUS/.env .env

# 3. Deploy
./deploy-update.sh alpha-motors-backend-X.X.X.tar.gz

# 4. Verify
curl http://localhost:3080/api-docs
docker logs alpha_backend --tail 20
```

---

## 🗃️ Database Schema Update (New Migration)

When you've added new migrations or changed entity definitions.

### Development Machine

```bash
# 1. Test migration locally first!
docker compose down -v                            # Fresh DB
docker compose -f docker-compose.build.yml build
docker compose up -d
npm run db:seed:all                               # Verify seeds work

# 2. If all good, commit
git add -A
git commit -m "Migration: add new_feature table"

# 3. Bump version
nano package.json  # Update version

# 4. Build and transfer
./scripts/build-release.sh
scp -r release/alpha-motors-vX.X.X user@server:/opt/alpha-motors/
```

### Production Server

```bash
cd /opt/alpha-motors/alpha-motors-vX.X.X
cp ../alpha-motors-vPREVIOUS/.env .env

# Deploy - migrations run automatically via entrypoint.sh
./deploy-update.sh alpha-motors-backend-X.X.X.tar.gz

# If seeds needed for new tables:
./deploy-update.sh alpha-motors-backend-X.X.X.tar.gz --seed
```

---

## 🌱 Seed Data Update

When car brands, currencies, or other seed data has changed.

### Development Machine

```bash
# 1. Update seed files
nano dumpCurrencies.js
nano cars.brands.json

# 2. Test locally
npm run db:seed:all

# 3. Commit and build
git add -A
git commit -m "Update currency rates / add new brands"
./scripts/build-release.sh
```

### Production Server

```bash
cd /opt/alpha-motors/alpha-motors-vX.X.X
cp ../alpha-motors-vPREVIOUS/.env .env

# Deploy with --seed flag
./deploy-update.sh alpha-motors-backend-X.X.X.tar.gz --seed
```

---

## 🚨 Emergency Rollback

If an update breaks production.

```bash
# 1. Check what's wrong
docker logs alpha_backend --tail 100

# 2. Stop broken container
docker compose -f docker-compose.prod.yml stop api

# 3. Go to previous version directory
cd /opt/alpha-motors/alpha-motors-vPREVIOUS

# 4. Load old image
gunzip -c alpha-motors-backend-PREVIOUS.tar.gz | docker load

# 5. Tag as latest
docker tag alpha-motors-backend:PREVIOUS alpha-motors-backend:latest

# 6. Start old version
docker compose -f docker-compose.prod.yml up -d api

# 7. If DB was corrupted, restore backup
docker exec -i auto_tm_postgres pg_restore -U auto_tm -d auto_tm --clean \
  < /opt/alpha-motors/alpha-motors-vX.X.X/backups/auto_tm_backup_TIMESTAMP.dump
```

---

## ✅ Pre-Release Verification Checklist

Before building a release, verify locally:

### Code Quality
- [ ] `npm run lint` passes
- [ ] `npm run test` passes (if tests exist)
- [ ] No TypeScript errors in build

### Database
- [ ] Fresh `docker compose down -v && docker compose up -d` works
- [ ] `npm run db:seed:all` completes successfully
- [ ] Entity files match migration columns

### API Functionality
- [ ] API starts: `curl http://localhost:3080/api-docs`
- [ ] Test core flows:
  - [ ] OTP send/verify
  - [ ] Post creation with photos
  - [ ] Brand/model listing

### Version
- [ ] `package.json` version updated
- [ ] Changes committed to git

---

## 📋 Seeding Quick Reference

| When to Seed | Command Flag |
|--------------|--------------|
| First deployment | `--seed` |
| New currency rates added | `--seed` |
| New car brands/models added | `--seed` |
| Demo data needed | `--seed-posts` |
| Code-only update | (no flag) |
| Routine bug fix | (no flag) |

**Seed scripts (for manual runs):**

```bash
# Inside container
docker exec alpha_backend node scripts/seed-all.js

# From host (requires env vars)
export DATABASE_HOST=localhost DATABASE_PORT=5432 \
       DATABASE_USERNAME=auto_tm DATABASE_PASSWORD=xxx DATABASE=auto_tm
npm run db:seed:all
```

---

## 🔑 Environment Variables Reference

**Must change for production:**
| Variable | Notes |
|----------|-------|
| `DATABASE_PASSWORD` | Strong unique password |
| `ACCESS_TOKEN_SECRET_KEY` | 64+ random chars |
| `REFRESH_TOKEN_SECRET_KEY` | 64+ random chars (different!) |
| `FIREBASE_*` | Real Firebase credentials |

**Remove/change for production:**
| Variable | Notes |
|----------|-------|
| `TEST_OTP_NUMBERS` | Remove or use fake numbers |
| `TEST_OTP_PREFIX` | Remove or use unused prefix |

**Keep same across versions:**
| Variable | Notes |
|----------|-------|
| `DATABASE_HOST` | `db` (Docker service name) |
| `PORT` | `3080` unless changing reverse proxy |
| `NODE_ENV` | `production` |

---

## 📊 Version History Template

Maintain a `CHANGELOG.md` or track versions here:

| Version | Date | Changes |
|---------|------|---------|
| 0.1.0 | 2026-01-15 | Initial release |
| 0.2.0 | 2026-01-28 | Added vlog support, fixed OTP flow |
| 0.3.0 | 2026-02-04 | Fixed photo upload junction table, added validation |
| 0.3.1 | 2026-02-06 | Fixed BelongsToMany FK references |
