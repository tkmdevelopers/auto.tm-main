# Alpha Motors (auto.tm) — Flutter App Documentation

> **Version:** 1.0.0+3 &nbsp;|&nbsp; **Dart SDK:** ^3.9.2 &nbsp;|&nbsp; **Last updated:** February 8, 2026  
> **Test Status:** ✅ 250/250 tests passing (1 skipped)

Alpha Motors is a car marketplace mobile application built with **Flutter + GetX** on the frontend and **NestJS + PostgreSQL** on the backend. It supports OTP-based phone authentication, car listing CRUD with photo/video upload, real-time push notifications, brand subscriptions, blog publishing with a rich-text editor, multi-language (EN / TM / RU), multi-currency (TMT / USD), and dark mode.

---

## Documentation Index

| Document | Purpose |
|----------|---------|
| [ARCHITECTURE.md](ARCHITECTURE.md) | Layered architecture, dependency injection graph, state management strategy, services layer, data model locations |
| [APP_FLOW.md](APP_FLOW.md) | Every user journey mapped end-to-end — auth, post creation, browsing, profile, favorites, blog, notifications |
| [API_REFERENCE.md](API_REFERENCE.md) | All REST endpoints grouped by domain, request/response shapes, token lifecycle, and the auto-refresh interceptor |
| [EMPIRICAL_EVALUATION.md](EMPIRICAL_EVALUATION.md) | Quantitative codebase metrics, code quality analysis, test coverage assessment, and architectural evaluation |
| [FUTURE_IMPROVEMENTS.md](FUTURE_IMPROVEMENTS.md) | Prioritised roadmap: dead code removal, consolidation, further refactoring, testing, and new features |

### Backend Documentation (cross-reference)

The NestJS backend has its own documentation suite at [`../../backend/docs/`](../../backend/docs/):

| Document | Purpose |
|----------|---------|
| [ARCHITECTURE.md](../../backend/docs/ARCHITECTURE.md) | Runtime topology, key modules, OTP flow, SMS device gateway |
| [API_REFERENCE.md](../../backend/docs/API_REFERENCE.md) | Backend endpoint contracts |
| [DATABASE.md](../../backend/docs/DATABASE.md) | PostgreSQL schema and table reference |
| [DEVELOPMENT_SETUP.md](../../backend/docs/DEVELOPMENT_SETUP.md) | Local dev environment setup |
| [PRODUCTION_DEPLOYMENT.md](../../backend/docs/PRODUCTION_DEPLOYMENT.md) | Docker deployment guide |

---

## Tech Stack at a Glance

```
┌──────────────────────────────────────────────────┐
│                  Flutter App                      │
│  State: GetX  │  HTTP: Dio  │  Auth: OTP + JWT   │
│  Storage: flutter_secure_storage + GetStorage     │
│  Media: image_picker, video_compress, chewie      │
│  Push: firebase_messaging + flutter_local_notif.  │
│  i18n: 3 locales  │  Theme: light + dark          │
├──────────────────────────────────────────────────┤
│                 NestJS Backend                    │
│  ORM: Sequelize  │  DB: PostgreSQL               │
│  HTTP :3080  │  WS :3090 (chat)  │  SMS :3091    │
│  Auth: Passport JWT  │  SMS: Physical device GW   │
└──────────────────────────────────────────────────┘
```

---

## How to Read These Docs

| If you want to… | Start with |
|------------------|------------|
| Understand the codebase structure | [ARCHITECTURE.md](ARCHITECTURE.md) |
| Trace a user journey end-to-end | [APP_FLOW.md](APP_FLOW.md) |
| Know which endpoint a screen calls | [API_REFERENCE.md](API_REFERENCE.md) |
| Assess code quality and tech debt | [EMPIRICAL_EVALUATION.md](EMPIRICAL_EVALUATION.md) |
| See what's planned next | [FUTURE_IMPROVEMENTS.md](FUTURE_IMPROVEMENTS.md) |

> **Note:** All Mermaid diagrams render natively on GitHub, GitLab, and VS Code (with Markdown Preview Mermaid extension).

---

## Quick Start

```bash
# 1. Clone & install
cd auto.tm-main
flutter pub get

# 2. Configure environment
cp .env.example .env   # set API_BASE=http://your-api:3080/

# 3. Run
flutter run
```

For backend setup, see [DEVELOPMENT_SETUP.md](../../backend/docs/DEVELOPMENT_SETUP.md).

---

## Known Quirks

- **Directory typo:** `lib/services/notification_sevice/` is missing the 'r' in "service". This is tracked in [FUTURE_IMPROVEMENTS.md](FUTURE_IMPROVEMENTS.md) as a P0 fix.
- **Font family:** `pubspec.yaml` declares the family as `Poppins` but bundles Inter font files. `AppThemes` references `'Inter'`.
