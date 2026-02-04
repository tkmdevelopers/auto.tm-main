# Database Sync vs Migrations - Best Practices

## ❌ **DO NOT USE DATABASE SYNC**

### Why Database Sync is Dangerous

**Database sync (`sequelize.sync()` or `sequelize.sync({ alter: true })`) should NEVER be used in production or development because:**

1. **Data Loss Risk**: Sync can **DROP COLUMNS AND TABLES** that don't match your entities
2. **No Version Control**: Changes aren't tracked in migration files
3. **Unpredictable**: Sync behavior changes between Sequelize versions
4. **Production Risk**: Can cause downtime and data loss in production
5. **No Rollback**: Can't undo sync changes easily
6. **Team Conflicts**: Different developers might have different entity states

### What Sync Does (Why It's Bad)

```typescript
// ❌ BAD - Never do this
sequelize.sync({ alter: true });
// This will:
// - Drop columns that don't exist in your entity
// - Drop tables that aren't in your models
// - Change column types (potentially losing data)
// - No way to track what changed
```

## ✅ **USE MIGRATIONS INSTEAD**

### Why Migrations are Better

1. **Version Controlled**: All changes tracked in Git
2. **Safe**: Can review changes before applying
3. **Reversible**: Can undo migrations
4. **Team Friendly**: Everyone applies same changes
5. **Production Safe**: Tested before deployment
6. **History**: Full audit trail of schema changes

### Migration Best Practices

```bash
# ✅ GOOD - Use migrations
npm run db:migrate        # Apply migrations
npm run db:migrate:undo   # Undo last migration
npm run db:migrate:status # Check status
```

## 🔧 **Current Setup**

Your project is correctly configured to use **migrations-only**:

- ✅ No `sequelize.sync()` calls in code
- ✅ Migrations run automatically via Docker entrypoint
- ✅ Baseline migration handles existing tables
- ✅ Environment-based configuration

**Note**: The `DB_AUTO_SYNC=true` in your `.env` is **ignored** - there's no code that reads it. It's safe to remove.

## 🛠️ **Fixing Schema Issues**

### Step 1: Check Actual Database Schema

```bash
# See what columns actually exist in your database
npm run db:check-schema
```

This will show you:
- All tables and their columns
- Missing columns
- Column types and constraints

### Step 2: Update Baseline Migration

The baseline migration now handles existing tables by:
- Checking if table exists
- If exists: Adding missing columns (doesn't drop anything)
- If not exists: Creating table with all columns

### Step 3: Run Migration

```bash
# The migration will now add missing columns to existing tables
npm run db:migrate
```

## 📋 **What We Fixed**

### Updated Tables in Baseline Migration

1. **users** - Adds missing `location`, `access`, `firebaseToken`, fixes `email` constraint
2. **brands** - Adds missing `name` and `location` columns
3. **models** - Adds missing `name`, `yearstart`, `yearend` columns, handles `brandId` vs `brandsId`

### Migration Logic

The migration now:
- ✅ Creates tables if they don't exist
- ✅ Adds missing columns if table exists
- ✅ Never drops columns or tables
- ✅ Handles column renames (e.g., `refreshToke` → `refreshToken`)
- ✅ Ensures indexes exist

## 🎯 **Recommendation**

**Use migrations only. Never enable database sync.**

Your current setup is correct:
- Migrations-only approach ✅
- Baseline migration handles existing tables ✅
- Safe column additions ✅

If you see schema mismatches:
1. Run `npm run db:check-schema` to see actual schema
2. Update baseline migration to add missing columns
3. Run `npm run db:migrate` to apply changes

This is the **safe, production-ready** approach.
