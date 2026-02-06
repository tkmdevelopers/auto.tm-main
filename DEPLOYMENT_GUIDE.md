# Alpha Motors - Deployment Guide

Setup and deployment guide for the Alpha Motors project (Flutter mobile app + NestJS backend + PostgreSQL).

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Backend Setup](#backend-setup)
   - [Local Development Workflow](#local-development-workflow-recommended)
3. [Flutter App Setup](#flutter-app-setup)
4. [Testing and Verification](#testing-and-verification)
5. [Common Issues](#common-issues)
6. [Production Deployment (Ubuntu Server)](#production-deployment-ubuntu-server)
   - [Updating the Backend (Air-Gapped Server)](#updating-the-backend-air-gapped-server)

---

## Prerequisites

### Required Software

- **Docker Desktop** (Windows/Mac) or **Docker Engine** (Linux) — version 20.10+
  https://www.docker.com/products/docker-desktop
- **Flutter SDK** 3.9.2+
  https://flutter.dev/docs/get-started/install
- **Android Studio** (for Android development)
  https://developer.android.com/studio
- **Xcode** (for iOS, Mac only) — from Mac App Store
- **Git** — https://git-scm.com/downloads

### System Requirements

- RAM: 8 GB minimum (16 GB recommended)
- Storage: 20 GB free
- OS: Windows 10/11, macOS 10.15+, or Ubuntu 20.04+

---

## Backend Setup

### Step 1: Clone the Repository

```bash
git clone https://github.com/tkmdevelopers/auto.tm-main.git
cd auto.tm-main/backend
```

### Step 2: Configure Environment Variables

```bash
cp .env.example .env
nano .env
```

Backend `.env` configuration:

```properties
# Database
DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_USERNAME=auto_tm
DATABASE_PASSWORD=YourSecurePasswordHere123!
DATABASE=auto_tm

# JWT Secrets (CHANGE THESE — generate with: openssl rand -base64 64)
ACCESS_TOKEN_SECRET_KEY="your-random-256-bit-secret-here"
REFRESH_TOKEN_SECRET_KEY="your-different-random-256-bit-secret-here"

# Email (for OTP dispatch)
EMAIL_USER="your-email@gmail.com"
EMAIL_PASSWORD="your-app-specific-password"

# Firebase (for push notifications)
FIREBASE_PROJECT_ID="your-project-id"
FIREBASE_CLIENT_EMAIL="your-service-account@your-project.iam.gserviceaccount.com"
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nYourPrivateKeyHere\n-----END PRIVATE KEY-----\n"
```

> Never commit `.env` to version control. For Gmail, use App Passwords: https://support.google.com/accounts/answer/185833

### Step 3: Build the Docker Image

**Option A — Build locally (with internet):**

```bash
docker compose -f docker-compose.build.yml build api
```

**Option B — Load pre-built image (offline):**

```bash
gunzip -c alpha-motors-backend-0.2.0.tar.gz | docker load
```

### Step 4: Start the Services

```bash
docker compose up -d
docker ps
docker logs alpha_backend --tail 100 -f
```

Expected output:

```
[entrypoint] Postgres is ready
[entrypoint] Running migrations (offline safe)
[database] Connection authenticated successfully
[NestJS] Application is running on: http://localhost:3080
```

> Postgres is exposed at `localhost:5432` so local scripts can connect directly.

### Step 5: Verify Backend

- Swagger docs: http://localhost:3080/api-docs

Check the database:

```bash
docker exec -it auto_tm_postgres psql -U auto_tm -d auto_tm -c '\dt'
```

### Step 6: Seed Initial Data

After migrations complete, seed currencies, brands, and models:

```bash
cd backend
npm run db:init
```

What gets seeded:
- Currencies: TMT (base), USD (19.5), CNY (2.7)
- Car brands and models from `cars.brands.json`

Individual seed commands:

```bash
npm run db:seed:currencies   # currencies only
npm run db:seed:brands       # brands and models only
```

Verify:

```bash
docker exec -it auto_tm_postgres psql -U auto_tm -d auto_tm \
  -c "SELECT * FROM convert_prices;"
docker exec -it auto_tm_postgres psql -U auto_tm -d auto_tm \
  -c "SELECT COUNT(*) FROM brands;"
docker exec -it auto_tm_postgres psql -U auto_tm -d auto_tm \
  -c "SELECT COUNT(*) FROM models;"
```

> Seed scripts use `.env` variables and work with both local and Docker setups.

### Reset / Clean Rebuild (Dev)

If your schema has drifted, reset the database:

```bash
docker compose down -v      # removes the Postgres volume
docker compose up -d        # fresh DB, migrations auto-run
cd backend && npm run db:init
```

> Never edit old migrations after they've been applied. Add new migrations instead.

### Local Development Workflow (Recommended)

Run Postgres in Docker with NestJS running natively for hot-reload and debugger support.

```
┌─────────────────────────────────────────────┐
│  Your Mac                                   │
│                                             │
│  ┌─────────────────┐   ┌────────────────┐  │
│  │  Docker          │   │  Native Node   │  │
│  │  ┌─────────────┐ │   │                │  │
│  │  │ PostgreSQL   │◄├───┤  NestJS API    │  │
│  │  │ port 5432    │ │   │  port 3080     │  │
│  │  └─────────────┘ │   │                │  │
│  └─────────────────┘   └────────────────┘  │
└─────────────────────────────────────────────┘
```

#### 1. Set `DATABASE_HOST=localhost` in `.env`

```properties
DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_USERNAME=auto_tm
DATABASE_PASSWORD=Key_bismynick1
DATABASE=auto_tm
```

> The `docker-compose.yml` api service overrides `DATABASE_HOST=db` internally. The `localhost` value is only used by your native Node process.

#### 2. Start Postgres only

```bash
cd backend
docker compose up db -d
docker compose ps   # should show auto_tm_postgres running
```

#### 3. Install dependencies, migrate, and seed

```bash
npm install
npm run db:migrate
npm run db:seed:all
```

Or reset everything from scratch:

```bash
npm run db:seed:fresh
```

#### 4. Start the dev server

```bash
npm run start:dev
```

API at http://localhost:3080 with hot-reload. Swagger at http://localhost:3080/api-docs.

#### 5. Day-to-day commands

| Task | Command |
|------|---------|
| Start Postgres | `docker compose up db -d` |
| Stop Postgres | `docker compose stop db` |
| Start API (hot-reload) | `npm run start:dev` |
| Run migrations | `npm run db:migrate` |
| Undo last migration | `npm run db:migrate:undo` |
| Seed base data | `npm run db:seed:all` |
| Seed demo posts (API must be running) | `npm run db:seed:demo-posts` |
| Full reset + seed | `npm run db:seed:fresh` |
| Check migration status | `npm run db:migrate:status` |
| Lint | `npm run lint` |
| Format | `npm run format` |
| Run tests | `npm run test` |

#### 6. When to use the Docker API container

The `api` service in `docker-compose.yml` is for convenience, not daily dev. Use it when:

- Testing the exact production Docker image locally
- Verifying the entrypoint/migration flow in a container
- Final smoke test before building a release

```bash
docker compose -f docker-compose.build.yml build api
docker compose up -d
docker compose down
```

> Port conflict: don't run `npm run start:dev` and the Docker API container simultaneously on port 3080.

---

## Flutter App Setup

### Step 1: Navigate to Flutter Directory

```bash
cd auto.tm-main   # from project root
```

### Step 2: Configure Environment

Create `.env` in the Flutter app root:

```properties
# Local development
API_BASE=http://localhost:3080/

# Android emulator (host loopback)
# API_BASE=http://10.0.2.2:3080/

# Physical device (same WiFi — use your machine's LAN IP)
# API_BASE=http://192.168.1.X:3080/

# Production
# API_BASE=https://your-domain.com/
```

Network reference:
- iOS Simulator: `localhost:3080`
- Android Emulator: `10.0.2.2:3080`
- Physical device: your machine's LAN IP + `:3080`

### Step 3: Install Dependencies

```bash
flutter pub get
flutter doctor -v
```

### Step 4: Configure Firebase

1. Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) from Firebase Console.
2. Place in `android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist`.
3. Update `lib/firebase_options.dart` with your config.

### Step 5: Run the App

```bash
flutter devices        # list available targets
flutter run            # run on default device
flutter build apk --release   # Android APK
flutter build ios --release   # iOS (Mac only)
```

---

## Testing and Verification

### Backend API

For full endpoint documentation, error codes, rate limits, and curl smoke tests, see **[backend/API_REFERENCE.md](backend/API_REFERENCE.md)**.

Quick health check:

```bash
curl -s http://localhost:3080/api-docs | head -5
```

### Flutter App Smoke Test

1. **Fresh login** — app opens to `/register`, enter phone, verify OTP, lands on home screen.
2. **Session persistence** — kill and relaunch the app; should stay logged in (validates via `/auth/me`).
3. **Token refresh** — after 15 minutes, any API call triggers transparent interceptor refresh with no user interruption.
4. **Concurrent requests** — multiple simultaneous calls when token is expired; only one refresh fires (mutex in interceptor).
5. **Logout** — clears tokens, redirects to `/register`; relaunching also goes to `/register`.

### Database Verification

```bash
# Confirm refreshTokenHash column exists (old refreshToken column removed)
docker exec auto_tm_postgres psql -U auto_tm -d auto_tm \
  -c "SELECT column_name FROM information_schema.columns
      WHERE table_name='users'
        AND column_name IN ('refreshToken','refreshTokenHash');"
```

---

## Common Issues

### Port 3080 already in use

```bash
lsof -i :3080          # Mac/Linux
netstat -ano | findstr :3080   # Windows
```

Kill the conflicting process or change the port in `docker-compose.yml`.

### Connection refused to PostgreSQL

```bash
docker ps | grep postgres      # is the container running?
docker compose down && docker compose up -d
docker logs auto_tm_postgres   # check for errors
```

### Migrations failed

```bash
docker exec alpha_backend npx sequelize-cli db:migrate:status
docker exec alpha_backend npx sequelize-cli db:migrate:undo
docker exec alpha_backend npx sequelize-cli db:migrate
```

### Flutter can't connect to API (Android emulator)

Set `API_BASE=http://10.0.2.2:3080/` in the Flutter `.env` and restart the app.

### Flutter can't connect (physical device)

Ensure the phone and your machine are on the same WiFi. Set `API_BASE=http://<your-lan-ip>:3080/`.

### Flutter packages not found

```bash
flutter clean && flutter pub get
```

### Gradle build failed (Android)

```bash
cd android && ./gradlew clean && cd ..
flutter clean && flutter pub get && flutter run
```

---

## Production Deployment (Ubuntu Server)

### Server Prerequisites

```bash
sudo apt update && sudo apt upgrade -y
curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh
sudo apt install docker-compose-plugin
sudo usermod -aG docker $USER && newgrp docker
```

### Transfer Files

```bash
scp -r backend/ user@server-ip:/opt/alpha-motors/
# or
rsync -avz --progress backend/ user@server-ip:/opt/alpha-motors/backend/
```

### Production Environment

```bash
ssh user@server-ip
cd /opt/alpha-motors/backend
nano .env
```

Key differences from development:

```properties
DATABASE_HOST=db                              # Docker internal network
DATABASE_PASSWORD=YourStrongProductionPassword
ACCESS_TOKEN_SECRET_KEY="prod-secret-256-bits"
REFRESH_TOKEN_SECRET_KEY="prod-refresh-secret-256-bits"
```

### Start the Stack

```bash
gunzip -c alpha-motors-backend-0.2.0.tar.gz | docker load
docker compose -f docker-compose.prod.yml up -d
docker logs alpha_backend --tail 100 -f
```

### Seed Data on Production

All seed scripts are included in the Docker image. No Node.js needed on the server.

**Option A — Seed during deploy (recommended):**

```bash
./deploy-update.sh alpha-motors-backend-0.2.0.tar.gz --seed          # base data only
./deploy-update.sh alpha-motors-backend-0.2.0.tar.gz --seed-posts    # base + ~300 demo posts
```

**Option B — Seed manually:**

```bash
docker exec alpha_backend node scripts/seed-all.js                   # currencies + brands/models
docker exec alpha_backend node scripts/seed-demo-posts-api.js        # ~300 demo posts
```

**Option C — Auto-seed on container start:**

Add `SEED_ON_START=true` to `.env` or `docker-compose.prod.yml`. The entrypoint runs base seeding (idempotent) after every migration.

Verify:

```bash
docker exec auto_tm_postgres psql -U auto_tm -d auto_tm \
  -c "SELECT label, rate FROM convert_prices ORDER BY label;"
docker exec auto_tm_postgres psql -U auto_tm -d auto_tm \
  -c "SELECT COUNT(*) FROM brands;"
docker exec auto_tm_postgres psql -U auto_tm -d auto_tm \
  -c "SELECT COUNT(*) FROM posts WHERE status = true;"
```

> Run base seeding after migrations complete but before the app goes live. Demo posts can be seeded any time while the API is running.

### NGINX Reverse Proxy (Optional)

```bash
sudo apt install nginx
sudo nano /etc/nginx/sites-available/alpha-motors
```

```nginx
server {
    listen 80;
    server_name api.yourdomain.com;

    location / {
        proxy_pass http://localhost:3080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

```bash
sudo ln -s /etc/nginx/sites-available/alpha-motors /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d api.yourdomain.com
```

### Automated Backups

```bash
sudo nano /usr/local/bin/backup-alpha-motors.sh
```

```bash
#!/bin/bash
set -e
BACKUP_DIR="/opt/backups/alpha-motors"
DATE=$(date +%Y%m%d_%H%M)
mkdir -p $BACKUP_DIR
docker exec auto_tm_postgres pg_dump -U auto_tm -d auto_tm -F c > $BACKUP_DIR/db_$DATE.dump
find $BACKUP_DIR -name "db_*.dump" -mtime +7 -delete
echo "Backup completed: db_$DATE.dump"
```

```bash
sudo chmod +x /usr/local/bin/backup-alpha-motors.sh
sudo crontab -e
# Add: 0 2 * * * /usr/local/bin/backup-alpha-motors.sh >> /var/log/alpha-backup.log 2>&1
```

### Firewall

```bash
sudo ufw allow 22 80 443
sudo ufw allow 3080   # only if not using NGINX
sudo ufw enable
```

### Monitoring

```bash
docker logs alpha_backend --tail 100 -f
docker logs auto_tm_postgres --tail 100 -f
docker stats
```

### Updating the Backend (Air-Gapped Server)

The production server has no internet. Updates follow a **build locally, transfer, deploy** workflow using two scripts:

- `scripts/build-release.sh` — local machine
- `scripts/deploy-update.sh` — server

#### Step 1: Bump the version

Edit `package.json`:

```json
{ "version": "0.2.0" }
```

Semver: patch (0.0.x) for fixes, minor (0.x.0) for features, major (x.0.0) for breaking changes.

#### Step 2: Build a release bundle

```bash
cd backend
./scripts/build-release.sh
```

Output:

```
release/alpha-motors-v0.2.0/
  alpha-motors-backend-0.2.0.tar.gz   # Docker image
  docker-compose.prod.yml
  .env.example
  deploy-update.sh
  scripts/pg_backup.sh
  VERSION
```

#### Step 3: Transfer to server

```bash
scp -r release/alpha-motors-v0.2.0 user@server-ip:/opt/alpha-motors/
# or copy via USB
```

#### Step 4: Deploy

```bash
ssh user@server-ip
cd /opt/alpha-motors/alpha-motors-v0.2.0
chmod +x deploy-update.sh
./deploy-update.sh alpha-motors-backend-0.2.0.tar.gz
```

The script: backs up the DB, loads the new image, restarts the API (migrations run via entrypoint), verifies health, and rolls back automatically if health check fails.

#### Rollback

```bash
docker tag alpha-motors-backend:0.1.0 alpha-motors-backend:latest
docker compose -f docker-compose.prod.yml up -d api

# Restore DB if a bad migration corrupted data
docker exec -i auto_tm_postgres pg_restore -U auto_tm -d auto_tm --clean \
  < backups/auto_tm_backup_YYYYMMDD_HHMMSS.dump
```

> Old images remain in Docker's store until pruned. Keep at least the previous version for rollback.

#### Pinning a specific version

```bash
API_IMAGE_TAG=alpha-motors-backend:0.1.0 docker compose -f docker-compose.prod.yml up -d api
```

---

## Building Flutter for Production

### Android

```bash
flutter build apk --release       # APK for direct install
flutter build appbundle --release  # AAB for Google Play

# Output:
# build/app/outputs/flutter-apk/app-release.apk
# build/app/outputs/bundle/release/app-release.aab
```

### iOS (Mac only)

```bash
flutter build ios --release
open ios/Runner.xcworkspace   # sign and upload via Xcode
```

Before building:
1. Set `API_BASE` in `.env` to the production URL.
2. Bump `version` in `pubspec.yaml`.
3. Configure signing in Android Studio / Xcode.

---

## Security Checklist

- [ ] Generate new JWT secrets (`openssl rand -base64 64`)
- [ ] Change all default passwords
- [ ] Set up HTTPS/SSL
- [ ] Configure firewall rules
- [ ] Set up automated backups
- [ ] Disable debug logs in production
- [ ] Use environment variables (never hardcode secrets)
- [ ] Regular security updates

---

## Resources

- NestJS: https://docs.nestjs.com/
- Flutter: https://docs.flutter.dev/
- Docker: https://docs.docker.com/
- PostgreSQL: https://www.postgresql.org/docs/
- API Reference: [backend/API_REFERENCE.md](backend/API_REFERENCE.md)
