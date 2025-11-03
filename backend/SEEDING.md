# Backend Seeding Guide

This guide explains how to populate development data (80 posts + photos) to exercise image loading, caching, and feed performance.

## Scripts

Location: `backend/scripts/`

- `seed-posts.ts` – Creates 80 realistic posts (brand/model, price, year, mileage, metadata) and 1–5 photos each.
- `delete-seeded-posts.ts` – Removes seeded data (heuristic or all with `--all`).

## Prerequisites

1. PostgreSQL running and accessible. Supported env variable names (either set legacy or new):
   - Legacy: `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASS`
   - Current (used by `database.ts`): `DATABASE_HOST`, `DATABASE_PORT`, `DATABASE`, `DATABASE_USERNAME`, `DATABASE_PASSWORD`
   The seed script will bridge legacy names to the current ones automatically.
2. Install dependencies (from backend root):
   ```
   npm install --no-audit --no-fund
   ```
3. (Optional) Provide sample images: Place a few `.jpg` or `.png` files in `backend/scripts/sample-images/` to have local copies. If none exist, placeholder remote URLs will be used.

## Seeding (Windows cmd)

Basic:
```
set NODE_ENV=development
npx ts-node ./scripts/seed-posts.ts
```

If you still get module resolution errors for `src/...`, use path mapping loader:
```
set NODE_ENV=development
npx ts-node -r tsconfig-paths/register ./scripts/seed-posts.ts
```

Progress logs appear every 10 posts. Photos are copied (or placeholder URLs assigned) and basic aspect metadata computed.

## Deleting Seed Data

Current deletion uses a heuristic (recent posts) or aggressive delete.

```
set NODE_ENV=development
npx ts-node ./scripts/delete-seeded-posts.ts --all
```

If you want precise deletions later, add a `seedBatch` column to `Posts` & `Photo` tables and tag with the batch string (`dev_seed_2025_11_03`). Update the scripts accordingly.

## Extending

- Add sharp to extract real image dimensions for accuracy.
- Persist a `seedBatch` attribute for precise cleanup (migration + model update).
- Add a CLI arg (`--count 150`) to vary post count.
- Generate more nuanced price/year distributions per brand.

## Notes

- Safeguard: Both scripts abort if `NODE_ENV=production`.
- Photo junction linking may require manual insert depending on your `PhotoPosts` association; adapt where indicated.
- Adjust brand/model arrays to reflect real catalog if available.
- For performance telemetry, ensure feed queries include these new posts so Flutter client can measure cache hit/miss rates and load times under realistic scrolling.
