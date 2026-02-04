# Database Schema Fixes Summary

## Issues Found from Schema Check

Based on `npm run db:check-schema` output, the following schema inconsistencies were identified and fixed:

### ✅ Fixed Tables

#### 1. **brands** Table
**Issue**: Missing `name` and `location` columns (only had `uuid`)
**Fix**: Migration now adds missing columns to existing table
**Status**: ✅ Fixed in baseline migration

#### 2. **models** Table  
**Issue**: Missing `name`, `yearstart`, `yearend` columns
**Fix**: Migration now adds missing columns to existing table
**Status**: ✅ Fixed in baseline migration

#### 3. **posts** Table
**Issue**: 
- Has `brandId` but entity expects `brandsId` (column name mismatch)
- Missing: `categoryId`, `subscriptionId`, `userId`, `transmission`, `originalPrice`, `originalCurrency`, `location`, `status`, `credit`, `exchange`
**Fix**: Migration now renames `brandId` → `brandsId` and adds all missing columns
**Status**: ✅ Fixed in baseline migration

#### 4. **users** Table
**Issue**: Has legacy `otp` column (deprecated, OTP now in `otp_codes` table)
**Fix**: Column left in place for backward compatibility (not used by code)
**Status**: ✅ Handled (intentionally left for compatibility)

### ⚠️ Legacy Tables

#### **otp_temp** Table
**Status**: Legacy table still exists. OTP functionality now uses `otp_codes` table.
**Recommendation**: Can be dropped in future migration if no longer needed.

## Migration Strategy

The baseline migration now uses a **safe, additive approach**:

1. ✅ **Creates tables** if they don't exist (with all columns)
2. ✅ **Adds missing columns** if table exists (never drops columns)
3. ✅ **Renames columns** when needed (e.g., `brandId` → `brandsId`)
4. ✅ **Fixes constraints** (e.g., email NOT NULL → nullable)
5. ✅ **Ensures indexes** exist

## Running the Fix

```bash
cd backend

# 1. Check current schema
npm run db:check-schema

# 2. Run migration (will add missing columns)
npm run db:migrate

# 3. Verify fixes
npm run db:check-schema

# 4. Seed data
npm run db:seed:all
```

## Expected Results After Migration

After running the migration, you should see:

- ✅ `brands` table: Has `uuid`, `name`, `location`, `createdAt`, `updatedAt`
- ✅ `models` table: Has `uuid`, `name`, `brandId`, `yearstart`, `yearend`, `createdAt`, `updatedAt`
- ✅ `posts` table: Has all required columns including `brandsId`, `categoryId`, `subscriptionId`, `userId`, etc.
- ✅ `users` table: All columns present (including legacy `otp` column for compatibility)

## Why Not Use Database Sync?

**Database sync (`sequelize.sync()`) is dangerous** because:
- ❌ Can **DROP** columns and tables
- ❌ Can cause **data loss**
- ❌ Not version controlled
- ❌ Unpredictable behavior

**Migrations are safe** because:
- ✅ Only **ADD** columns (never drop)
- ✅ Version controlled
- ✅ Reversible
- ✅ Production-safe

Your project correctly uses **migrations-only** approach. ✅
