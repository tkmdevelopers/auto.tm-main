# Production Deployment Guide

Complete guide for deploying Alpha Motors backend to a production (potentially air-gapped) Ubuntu server.

## Overview

The deployment uses a **build-then-transfer** approach:
1. **Build** Docker image on your development machine (with internet)
2. **Transfer** the release bundle to the production server
3. **Deploy** using the provided scripts

---

## Prerequisites

### On Development Machine (Mac/Linux)
- Docker Desktop running
- Git with changes committed
- Node.js 20+ (for version extraction)

### On Production Server
- Ubuntu 20.04+ or similar Linux
- Docker Engine + Docker Compose v2
- At least 2GB RAM, 10GB disk
- Port 3080 accessible (or configure reverse proxy)

---

## Phase 1: Build Release Bundle

Run these commands on your **development machine**.

### 1.1 Update Version (Optional)

```bash
cd backend

# Edit package.json version if needed
nano package.json
# Change: "version": "0.3.0"

# Commit version bump
git add package.json
git commit -m "Bump version to 0.3.0"
```

### 1.2 Build Release

```bash
# Run the build script
./scripts/build-release.sh

# Or specify version explicitly
./scripts/build-release.sh 0.3.0
```

**What it does:**
1. ✅ Builds Docker image `alpha-motors-backend:0.3.0`
2. ✅ Also tags as `:latest`
3. ✅ Exports image to `release/alpha-motors-v0.3.0/alpha-motors-backend-0.3.0.tar.gz`
4. ✅ Copies compose file, env template, deploy scripts

**Output structure:**
```
release/alpha-motors-v0.3.0/
├── alpha-motors-backend-0.3.0.tar.gz   # Docker image (~300MB)
├── docker-compose.prod.yml              # Production compose
├── .env.example                         # Environment template
├── deploy-update.sh                     # Deployment script
├── VERSION                              # Version marker
└── scripts/
    └── pg_backup.sh                     # Backup utility
```

### 1.3 Transfer to Server

```bash
# SCP to server
scp -r release/alpha-motors-v0.3.0 user@server-ip:/opt/alpha-motors/

# Or for air-gapped: copy to USB drive
cp -r release/alpha-motors-v0.3.0 /Volumes/USB/
```

---

## Phase 2: First-Time Server Setup

Run these commands on the **production server**.

### 2.1 Prepare Directory

```bash
sudo mkdir -p /opt/alpha-motors
sudo mkdir -p /var/lib/alpha/uploads    # Persistent uploads directory
sudo chown -R $USER:$USER /opt/alpha-motors /var/lib/alpha

cd /opt/alpha-motors/alpha-motors-v0.3.0
```

### 2.2 Configure Environment

```bash
# Create production .env from template
cp .env.example .env
nano .env
```

**⚠️ CRITICAL: Change these values!**

```dotenv
# Database (CHANGE PASSWORD!)
DATABASE_PASSWORD=your_secure_password_here

# JWT Secrets (CHANGE THESE!)
ACCESS_TOKEN_SECRET_KEY=generate_random_64_char_string
REFRESH_TOKEN_SECRET_KEY=generate_different_64_char_string

# Firebase (your project credentials)
FIREBASE_PROJECT_ID=your-firebase-project
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxx@your-project.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----"

# Production flag
NODE_ENV=production

# OTP test controls (use ONLY if you want test OTP in production)
OTP_TEST_MODE=true
OTP_TEST_ALLOW_IN_PROD=true
TEST_OTP_NUMBERS_PROD=99361999999,99361999991
OTP_TEST_CODE_RESPONSE=true

⚠️ Only allow test OTPs for a short allowlist. Disable once testing is done.

# Per-phone OTP rate limiting
OTP_PHONE_RATE_LIMIT_WINDOW_MS=60000
OTP_PHONE_RATE_LIMIT_MAX=3
```

**Generate random secrets:**
```bash
openssl rand -base64 48  # Run twice, use for each secret
```

### 2.3 Deploy

```bash
chmod +x deploy-update.sh

# First deployment with seeding
./deploy-update.sh alpha-motors-backend-0.3.0.tar.gz --seed
```

**What `--seed` does:**
- Seeds currencies (TMT, USD, CNY)
- Seeds car brands (131) and models (2447)

**Expected output:**
```
Phase 1: Pre-flight checks ✓
Phase 2: Database backup (skipped - first deploy)
Phase 3: Loading Docker image ✓
Phase 4: Updating API container ✓
Phase 5: Health verification ✓
Phase 6: Seeding database ✓

Update successful!
```

### 2.4 Verify

```bash
# Check containers are running
docker ps

# Should show:
# alpha_backend      Up (healthy)
# auto_tm_postgres   Up (healthy)

# Test API
curl http://localhost:3080/api-docs

# Check logs
docker logs alpha_backend --tail 50
```

**API Documentation:** http://server-ip:3080/api-docs

---

## Phase 3: Updates (Subsequent Deployments)

For updates after the initial deployment.

### 3.1 Build New Version (Dev Machine)

```bash
cd backend
# Update version in package.json
./scripts/build-release.sh 0.4.0

# Transfer to server
scp -r release/alpha-motors-v0.4.0 user@server-ip:/opt/alpha-motors/
```

### 3.2 Deploy Update (Production Server)

```bash
cd /opt/alpha-motors/alpha-motors-v0.4.0

# Copy existing .env (DON'T recreate from example!)
cp ../alpha-motors-v0.3.0/.env .env

# Deploy (no --seed needed for updates unless schema changed)
./deploy-update.sh alpha-motors-backend-0.4.0.tar.gz
```

**Update process:**
1. ✅ Pre-flight checks
2. ✅ **Automatic database backup** before changes
3. ✅ Load new Docker image
4. ✅ Stop old container, start new
5. ✅ Health check verification
6. ✅ **Automatic rollback** if health check fails

### 3.3 Update with Re-seeding

If migrations added new seed requirements:

```bash
./deploy-update.sh alpha-motors-backend-0.4.0.tar.gz --seed
```

---

## Rollback Procedure

### Automatic Rollback

If health check fails during `deploy-update.sh`, it automatically:
1. Stops the broken container
2. Restores the previous image
3. Restarts with the old version

### Manual Rollback

```bash
cd /opt/alpha-motors

# 1. Stop current container
docker compose -f alpha-motors-v0.4.0/docker-compose.prod.yml stop api

# 2. Load old image
gunzip -c alpha-motors-v0.3.0/alpha-motors-backend-0.3.0.tar.gz | docker load

# 3. Tag as latest
docker tag alpha-motors-backend:0.3.0 alpha-motors-backend:latest

# 4. Restart with old version
cd alpha-motors-v0.3.0
docker compose -f docker-compose.prod.yml up -d api
```

### Database Rollback (if needed)

```bash
# Backups are stored automatically
ls /opt/alpha-motors/alpha-motors-v0.4.0/backups/

# Restore from backup
docker exec -i auto_tm_postgres pg_restore -U auto_tm -d auto_tm --clean \
  < /opt/alpha-motors/alpha-motors-v0.4.0/backups/auto_tm_backup_20260206_143000.dump
```

---

## Maintenance Tasks

### Database Backups

```bash
# Manual backup
docker exec auto_tm_postgres pg_dump -U auto_tm -d auto_tm -F c -Z 9 > backup.dump

# Or use provided script
./scripts/pg_backup.sh

# Backups location
/opt/alpha-motors/alpha-motors-vX.X.X/backups/
```

### Viewing Logs

```bash
# API logs
docker logs alpha_backend --tail 100
docker logs -f alpha_backend  # Follow mode

# Postgres logs
docker logs auto_tm_postgres --tail 50
```

### Container Health

```bash
# Check status
docker ps

# Restart API only
docker compose -f docker-compose.prod.yml restart api

# Full restart
docker compose -f docker-compose.prod.yml down
docker compose -f docker-compose.prod.yml up -d
```

### Disk Space

```bash
# Check uploads size
du -sh /var/lib/alpha/uploads

# Check Docker usage
docker system df

# Clean unused images (CAREFUL)
docker image prune -a
```

---

## Security Checklist

- [ ] Changed `DATABASE_PASSWORD` from default
- [ ] Generated unique `ACCESS_TOKEN_SECRET_KEY`
- [ ] Generated unique `REFRESH_TOKEN_SECRET_KEY`
- [ ] Configured real Firebase credentials
- [ ] Firewall allows only port 3080 (or reverse proxy port)
- [ ] Regular database backups scheduled
- [ ] `.env` file permissions restricted (`chmod 600 .env`)
- [ ] No test OTP numbers in production `.env`

---

## Nginx Reverse Proxy (Optional)

For HTTPS and domain access:

```nginx
server {
    listen 80;
    server_name api.yourdomain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.yourdomain.com;

    ssl_certificate /etc/letsencrypt/live/api.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.yourdomain.com/privkey.pem;

    # Max upload size (for photos/videos)
    client_max_body_size 100M;

    location / {
        proxy_pass http://127.0.0.1:3080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

---

## Architecture (Production)

```
/opt/alpha-motors/
├── alpha-motors-v0.3.0/          # Version folder
│   ├── docker-compose.prod.yml   # Compose file
│   ├── .env                      # Production config (KEEP SECRET!)
│   ├── deploy-update.sh          # Deployment script
│   ├── backups/                  # Auto-created DB backups
│   └── scripts/
└── alpha-motors-v0.4.0/          # Newer version
    └── ...

/var/lib/alpha/
└── uploads/                      # Persistent media storage
    ├── photos/
    └── videos/

Docker volumes:
└── db_data                       # PostgreSQL data (managed by Docker)
```
