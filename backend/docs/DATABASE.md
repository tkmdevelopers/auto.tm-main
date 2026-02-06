# Alpha Motors — Database Schema

PostgreSQL 16 via Sequelize. Schema is defined and evolved in **migrations** under `backend/migrations/`. This doc summarizes tables and relationships; the migration files are the source of truth.

---

## Migrations (Order)

| Migration | Purpose |
|-----------|---------|
| `20260202000000-baseline.js` | Full schema: users, otp_codes, brands, models, posts, photo, video, comments, vlogs, subscriptions, subscription_order, banners, categories, notification_history, convert_prices, file, junction tables |
| `20260203000000-schema-fixes-brands-convert-prices.js` | Schema fixes for brands and convert_prices |
| `20260206000000-refresh-token-hash.js` | **Breaking:** Replace `users.refreshToken` (plaintext) with `users.refreshTokenHash` (bcrypt). All sessions invalidated. |

Migrations run automatically on container startup via `docker/entrypoint.sh`. For local native runs: `npm run db:migrate` from `backend/`.

---

## Tables Overview

| Table | Purpose |
|-------|---------|
| **users** | Accounts: phone, name, email, role, refreshTokenHash, location, firebaseToken, etc. PK: `uuid`. |
| **otp_codes** | OTP send/verify: phone, purpose, codeHash, expiresAt, consumedAt, attempts, dispatchStatus. PK: `id` (UUID). |
| **brands** | Car brands. PK: `uuid`. |
| **models** | Car models. FK: `brandId` → brands. PK: `uuid`. |
| **categories** | Post categories. |
| **banners** | Homepage banners. |
| **subscriptions** | Premium subscription types. |
| **subscription_order** | User subscription orders. FK: user, subscription. |
| **posts** | Car listings. FKs: brandsId, modelsId, categoryId, subscriptionId, userId. PK: `uuid`. |
| **photo** | Photo records. Linked to posts/vlogs via junction. |
| **video** | Video records. |
| **file** | Generic file metadata. |
| **comments** | Comments on posts. FKs: userId, postId, replyTo (self). PK: `uuid`. |
| **vlogs** | Vlog entries. FK: userId. |
| **notification_history** | Push notification log. |
| **convert_prices** | Currency conversion data. |
| **brands_user** | M2M: users ↔ brands (e.g. subscribed brands). |
| **photo_posts** | M2M: photo ↔ posts. |
| **photo_vlog** | M2M: photo ↔ vlogs. |

---

## Key Relationships

- **users** ← posts (userId), comments (userId), vlogs (userId), subscription_order, brands_user. On user delete: FKs typically `ON DELETE SET NULL`.
- **posts** ← comments (postId, CASCADE), photo_posts. Posts reference brands, models, categories, subscriptions, users.
- **otp_codes** — Standalone; indexed by (phone, purpose), expiresAt, createdAt for cleanup and lookup.

---

## Users Table (Auth-Relevant)

After baseline + refresh-token-hash migration:

- **uuid** (PK), name, email, password, phone, status, role (admin | owner | user), **refreshTokenHash** (TEXT, bcrypt hash of current refresh token), location, access, firebaseToken, createdAt, updatedAt.
- Indexes on `phone`, `email`.

---

## Seeding

Required for normal operation:

- **Currencies** (e.g. TMT, USD, CNY) — `convert_prices` or related.
- **Brands and models** — 131 brands, 2447 models.

Commands: `npm run db:seed:all`, or `db:seed:currencies` / `db:seed:brands` (see [DEVELOPMENT_SETUP.md](DEVELOPMENT_SETUP.md)).

---

## Verification

```bash
# List tables
docker exec -it auto_tm_postgres psql -U auto_tm -d auto_tm -c '\dt'

# Users columns (expect refreshTokenHash, no refreshToken)
docker exec auto_tm_postgres psql -U auto_tm -d auto_tm \
  -c "SELECT column_name FROM information_schema.columns WHERE table_name='users' ORDER BY ordinal_position;"
```

---

## Reference

- Migrations: `backend/migrations/`
- Sequelize config: from env in `docker/entrypoint.sh`; programmatic config in `backend/src/database/`.
- Entities: `backend/src/{feature}/{feature}.entity.ts` (align with migrations).
