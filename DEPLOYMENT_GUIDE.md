# 🚀 Alpha Motors - Complete Deployment Guide

This guide will help you set up and run the **Alpha Motors** project (Flutter mobile app + NestJS backend) on a new computer.

---

## 📋 Table of Contents
1. [Prerequisites](#prerequisites)
2. [Backend Setup (NestJS + Docker + PostgreSQL)](#backend-setup)
3. [Flutter Mobile App Setup](#flutter-app-setup)
4. [Testing & Verification](#testing--verification)
5. [Common Issues & Solutions](#common-issues--solutions)
6. [Production Deployment (Ubuntu Server)](#production-deployment)

---

## 🔧 Prerequisites

### Required Software
- **Docker Desktop** (Windows/Mac) or **Docker Engine** (Linux)
  - Download: https://www.docker.com/products/docker-desktop
  - Minimum version: 20.10+
- **Flutter SDK** (3.9.2 or higher)
  - Download: https://flutter.dev/docs/get-started/install
- **Android Studio** (for Android development)
  - Download: https://developer.android.com/studio
- **Xcode** (for iOS development - Mac only)
  - Download from Mac App Store
- **Git**
  - Download: https://git-scm.com/downloads

### System Requirements
- **RAM**: 8GB minimum (16GB recommended)
- **Storage**: 20GB free space
- **OS**: Windows 10/11, macOS 10.15+, or Ubuntu 20.04+

---

## 🔙 Backend Setup

### Step 1: Clone the Repository

```bash
# Clone the repository
git clone https://github.com/tkmdevelopers/auto.tm-main.git
cd auto.tm-main/backend
```

### Step 2: Configure Environment Variables

Create a `.env` file in the `backend` directory:

```bash
# Copy the example file
cp .env.example .env

# Edit the .env file with your settings
nano .env  # or use any text editor
```

**Backend `.env` configuration:**

```properties
# Database Configuration (Docker)
DATABASE_HOST=db
# Host port to connect from your computer (also used by `npm run db:init`).
# If you already have local Postgres using 5432, set this to 5433.
DATABASE_PORT=5432
DATABASE_USERNAME=auto_tm
DATABASE_PASSWORD=YourSecurePasswordHere123!
DATABASE=auto_tm

# JWT Secrets (CHANGE THESE!)
ACCESS_TOKEN_SECRET_KEY="your-random-256-bit-secret-here"
REFRESH_TOKEN_SECRET_KEY="your-different-random-256-bit-secret-here"

# Email Configuration (for OTP)
EMAIL_USER="your-email@gmail.com"
EMAIL_PASSWORD="your-app-specific-password"

# Firebase Configuration (for push notifications)
FIREBASE_PROJECT_ID="your-project-id"
FIREBASE_CLIENT_EMAIL="your-service-account@your-project.iam.gserviceaccount.com"
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nYourPrivateKeyHere\n-----END PRIVATE KEY-----\n"
```

> **🔐 Security Note:** 
> - Generate strong random secrets for JWT tokens (use: `openssl rand -base64 64`)
> - Never commit the `.env` file to version control
> - For Gmail, use App Passwords: https://support.google.com/accounts/answer/185833

### Step 3: Build the Docker Image

You have two options:

#### Option A: Build Locally (With Internet)

```bash
# Build the backend Docker image
docker compose -f docker-compose.build.yml build api
```

#### Option B: Load Pre-built Image (Offline Deployment)

If you already have the `alpha_backend_1.0.0.tar` image:

```bash
# Load the image
docker load -i alpha_backend_1.0.0.tar

# Or if it's gzipped
gunzip -c alpha_backend_1.0.0.tar.gz | docker load
```

### Step 4: Start the Services

```bash
# Start PostgreSQL + Backend API
docker compose up -d

# Check if containers are running
docker ps

# View logs
docker logs alpha_backend --tail 100 -f
```

Expected output:
```
[entrypoint] Postgres is ready
[entrypoint] Running migrations (offline safe)
[database] Connection authenticated successfully
[NestJS] Application is running on: http://localhost:3080
```

> Note: Postgres is exposed to your host at `localhost:${DATABASE_PORT}` (see `backend/docker-compose.yml`). This is required for running `npm run db:init` from your terminal.

### Step 5: Verify Backend

Open your browser and visit:
- **API Documentation**: http://localhost:3080/api-docs
- **Health Check**: http://localhost:3080/api/v1/auth/login (should show login page)

You can also check the database:

```bash
# Connect to PostgreSQL
docker exec -it auto_tm_postgres psql -U auto_tm -d auto_tm

# List all tables
\dt

# Exit
\q
```

### Step 6: Seed Initial Data

After migrations complete, seed the database with initial data (currencies, car brands, and models):

```bash
# From the backend directory
cd backend

# One command: migrate + seed (recommended)
npm run db:init
```

**What gets seeded:**
- **Currencies**: TMT (base), USD (19.5), CNY (2.7)
- **Car Brands**: All car brands from `cars.brands.json`
- **Car Models**: All car models associated with brands

**Individual seed commands** (if needed):
```bash
# Seed only currencies
npm run db:seed:currencies

# Seed only car brands and models
npm run db:seed:brands
```

> **Important**: Seed scripts are **insert-only** and will **fail fast** if the schema is wrong.\n+> If you see “column does not exist”, reset the database and re-run `npm run db:init`.
\n
**Verify seeded data:**
```bash
# Check currencies
docker exec -it auto_tm_postgres psql -U auto_tm -d auto_tm -c "SELECT * FROM convert_prices;"

# Check brands count
docker exec -it auto_tm_postgres psql -U auto_tm -d auto_tm -c "SELECT COUNT(*) FROM brands;"

# Check models count
docker exec -it auto_tm_postgres psql -U auto_tm -d auto_tm -c "SELECT COUNT(*) FROM models;"
```

> **💡 Tip**: The seed scripts use environment variables from `.env`, so they work with both local and Docker setups automatically.

### Reset / Clean Rebuild (Dev)

If you previously ran older migrations and your schema drifted, the recommended fix is to **reset the database** and rebuild from the baseline migration.

```bash
# Stop containers
docker compose down -v

# `-v` removes the named Postgres volume (e.g. `backend_db_data`) so Postgres re-initializes cleanly.

# Start again (migrations auto-run)
docker compose up -d

# Seed everything
cd backend
npm run db:init
```

> **Anti-drift rule**: don’t edit old migrations after they’ve been applied. If schema needs to evolve, add a new migration.

---

## 📱 Flutter App Setup

### Step 1: Navigate to Flutter Directory

```bash
cd ../auto.tm-main
# or from project root: cd auto.tm-main
```

### Step 2: Configure Flutter Environment

Create a `.env` file in the Flutter app root directory:

```bash
# Create .env file
touch .env  # Mac/Linux
# or
type nul > .env  # Windows
```

**Flutter `.env` configuration:**

```properties
# Backend API Base URL
# For local development:
API_BASE=http://localhost:3080/

# For Android emulator accessing host machine:
# API_BASE=http://10.0.2.2:3080/

# For physical device on same network:
# API_BASE=http://YOUR_COMPUTER_IP:3080/

# For production server:
# API_BASE=https://your-domain.com/
```

> **📍 Network Configuration Tips:**
> - **Local browser testing**: `http://localhost:3080/`
> - **Android Emulator**: `http://10.0.2.2:3080/` (emulator's special IP for host)
> - **iOS Simulator**: `http://localhost:3080/`
> - **Physical Device (same WiFi)**: `http://192.168.1.X:3080/` (your computer's local IP)
> - **Production**: `https://your-domain.com/`

### Step 3: Install Dependencies

```bash
# Get Flutter packages
flutter pub get

# Verify Flutter setup
flutter doctor -v
```

Fix any issues reported by `flutter doctor`.

### Step 4: Configure Firebase (for Push Notifications)

1. Download your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) from Firebase Console
2. Place files in the correct locations:
   - Android: `android/app/google-services.json`
   - iOS: `ios/Runner/GoogleService-Info.plist`

3. Update `lib/firebase_options.dart` with your Firebase configuration

### Step 5: Run the App

#### For Android:

```bash
# List available devices
flutter devices

# Run on Android device/emulator
flutter run

# Or build APK
flutter build apk --release
```

#### For iOS (Mac only):

```bash
# Open iOS project
open ios/Runner.xcworkspace

# Or run directly
flutter run
```

#### For Windows/Linux/macOS Desktop:

```bash
# Run on desktop
flutter run -d windows  # Windows
flutter run -d macos    # macOS
flutter run -d linux    # Linux
```

---

## ✅ Testing & Verification

### Backend Health Check

```bash
# Test API endpoints
curl http://localhost:3080/api-docs

# Check database
docker exec auto_tm_postgres psql -U auto_tm -d auto_tm -c "SELECT COUNT(*) FROM users;"
```

### Flutter App Testing

1. **Registration Flow**:
   - Open the app → Sign up
   - Enter phone number → Verify OTP
   - Complete registration

2. **Create a Post**:
   - Navigate to "Post" tab
   - Fill in car details
   - Upload photos
   - Submit

3. **Browse Feed**:
   - Check home screen for posts
   - Test search and filters
   - View post details

---

## 🐛 Common Issues & Solutions

### Backend Issues

#### Issue: "Port 3080 already in use"

```bash
# Find process using port 3080
# Windows:
netstat -ano | findstr :3080

# Mac/Linux:
lsof -i :3080

# Kill the process or change port in docker-compose.yml
```

#### Issue: "Connection refused to PostgreSQL"

```bash
# Check if PostgreSQL container is running
docker ps | grep postgres

# Restart containers
docker compose down
docker compose up -d

# Check logs
docker logs auto_tm_postgres
```

#### Issue: "Migrations failed"

```bash
# Check migration status
docker exec alpha_backend npx sequelize-cli db:migrate:status

# Rollback and re-run
docker exec alpha_backend npx sequelize-cli db:migrate:undo
docker exec alpha_backend npx sequelize-cli db:migrate
```

### Flutter Issues

#### Issue: "Can't connect to API from Android emulator"

- Change `API_BASE` in `.env` to `http://10.0.2.2:3080/`
- Restart the app after changing `.env`

#### Issue: "Can't connect from physical device"

```bash
# Find your computer's local IP
# Windows:
ipconfig

# Mac/Linux:
ifconfig

# Update .env with your local IP
API_BASE=http://192.168.1.X:3080/
```

Make sure your phone and computer are on the same WiFi network.

#### Issue: "Flutter packages not found"

```bash
# Clean and reinstall
flutter clean
flutter pub get
flutter pub upgrade
```

#### Issue: "Gradle build failed (Android)"

```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

---

## 🌐 Production Deployment (Ubuntu Server)

### Prerequisites on Server

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose
sudo apt install docker-compose-plugin

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker
```

### Transfer Files to Server

```bash
# From your local machine
scp -r backend/ user@your-server-ip:/opt/alpha-motors/

# Or use rsync
rsync -avz --progress backend/ user@your-server-ip:/opt/alpha-motors/backend/
```

### Configure Production Environment

```bash
# SSH into server
ssh user@your-server-ip

# Navigate to backend
cd /opt/alpha-motors/backend

# Create production .env
nano .env
```

**Production `.env` changes:**

```properties
# Use 'db' for Docker internal network
DATABASE_HOST=db

# Change to production domain
API_BASE=https://api.yourdomain.com/

# Use strong passwords
DATABASE_PASSWORD=YourVeryStrongProductionPassword123!

# Production JWT secrets (generate new ones)
ACCESS_TOKEN_SECRET_KEY="new-production-secret-256-bits"
REFRESH_TOKEN_SECRET_KEY="new-production-refresh-secret-256-bits"
```

### Start Production Stack

```bash
# Load Docker image (if transferred)
docker load -i alpha_backend_1.0.0.tar

# Start with production compose
docker compose -f docker-compose.prod.yml up -d

# Check logs
docker logs alpha_backend --tail 100 -f
```

### Seed Initial Data (Required)

After the stack starts and migrations complete, seed the database with initial data:

```bash
# From the backend directory on server
cd /opt/alpha-motors/backend

# Run all seed scripts (currencies + brands/models)
npm run db:seed:all
```

**What gets seeded:**
- **Currencies**: TMT (base: 1.0), USD (19.5), CNY (2.7)
- **Car Brands**: All car brands from `cars.brands.json`
- **Car Models**: All car models associated with brands

**Verify seeded data:**
```bash
# Check currencies
docker exec auto_tm_postgres psql -U auto_tm -d auto_tm -c "SELECT label, rate FROM convert_prices ORDER BY label;"

# Check brands count
docker exec auto_tm_postgres psql -U auto_tm -d auto_tm -c "SELECT COUNT(*) as brand_count FROM brands;"

# Check models count
docker exec auto_tm_postgres psql -U auto_tm -d auto_tm -c "SELECT COUNT(*) as model_count FROM models;"
```

> **⚠️ Important**: Run seeding **after** migrations complete but **before** the app goes live. The seed scripts use environment variables from `.env`, so they work automatically with your production configuration.

### Setup NGINX Reverse Proxy (Optional but Recommended)

```bash
# Install NGINX
sudo apt install nginx

# Create config
sudo nano /etc/nginx/sites-available/alpha-motors
```

**NGINX configuration:**

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
# Enable site
sudo ln -s /etc/nginx/sites-available/alpha-motors /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx

# Setup SSL with Let's Encrypt (Recommended)
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d api.yourdomain.com
```

### Setup Automated Backups

Create backup script:

```bash
sudo nano /usr/local/bin/backup-alpha-motors.sh
```

```bash
#!/bin/bash
set -e

BACKUP_DIR="/opt/backups/alpha-motors"
DATE=$(date +%Y%m%d_%H%M)

mkdir -p $BACKUP_DIR

# Backup database
docker exec auto_tm_postgres pg_dump -U auto_tm -d auto_tm -F c > $BACKUP_DIR/db_$DATE.dump

# Keep only last 7 days
find $BACKUP_DIR -name "db_*.dump" -mtime +7 -delete

echo "Backup completed: db_$DATE.dump"
```

```bash
# Make executable
sudo chmod +x /usr/local/bin/backup-alpha-motors.sh

# Add to cron (daily at 2 AM)
sudo crontab -e

# Add this line:
0 2 * * * /usr/local/bin/backup-alpha-motors.sh >> /var/log/alpha-backup.log 2>&1
```

### Firewall Configuration

```bash
# Allow SSH, HTTP, HTTPS
sudo ufw allow 22
sudo ufw allow 80
sudo ufw allow 443

# If accessing API directly (without NGINX)
sudo ufw allow 3080

sudo ufw enable
sudo ufw status
```

### Monitoring & Logs

```bash
# View backend logs
docker logs alpha_backend --tail 100 -f

# View PostgreSQL logs
docker logs auto_tm_postgres --tail 100 -f

# Check container stats
docker stats

# View system resources
htop
```

---

## 📱 Building Flutter App for Production

### Android APK/Bundle

```bash
# Build APK (for direct installation)
flutter build apk --release

# Build App Bundle (for Google Play Store)
flutter build appbundle --release

# Output location:
# build/app/outputs/flutter-apk/app-release.apk
# build/app/outputs/bundle/release/app-release.aab
```

### iOS Build (Mac only)

```bash
# Build iOS app
flutter build ios --release

# Open in Xcode for signing and upload
open ios/Runner.xcworkspace
```

**Before building for production:**

1. Update `API_BASE` in `.env` to production URL:
   ```
   API_BASE=https://api.yourdomain.com/
   ```

2. Update version in `pubspec.yaml`:
   ```yaml
   version: 1.0.1+4  # version+build number
   ```

3. Configure app signing in Android Studio / Xcode

---

## 🔒 Security Checklist

- [ ] Change all default passwords
- [ ] Generate new JWT secrets (use `openssl rand -base64 64`)
- [ ] Setup HTTPS/SSL certificates
- [ ] Configure firewall rules
- [ ] Setup automated backups
- [ ] Disable debug logs in production
- [ ] Use environment variables (never hardcode secrets)
- [ ] Setup monitoring and alerts
- [ ] Regular security updates
- [ ] Database backups to external storage

---

## 📞 Support & Resources

- **NestJS Docs**: https://docs.nestjs.com/
- **Flutter Docs**: https://docs.flutter.dev/
- **Docker Docs**: https://docs.docker.com/
- **PostgreSQL Docs**: https://www.postgresql.org/docs/

---

## 🎉 You're All Set!

Your Alpha Motors application should now be running successfully. If you encounter any issues:

1. Check the logs: `docker logs alpha_backend -f`
2. Verify environment variables in `.env` files
3. Ensure all ports are accessible
4. Check firewall settings
5. Review the troubleshooting section above

**Happy coding! 🚀**
