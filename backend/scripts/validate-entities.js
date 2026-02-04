#!/usr/bin/env node
/**
 * Entity-Schema Validation Script
 * 
 * Validates that Sequelize entities match the database schema.
 * Run this before deployment to catch column name mismatches.
 * 
 * Usage:
 *   npm run db:validate
 *   or
 *   node scripts/validate-entities.js
 */

const { Client } = require('pg');
const path = require('path');
const fs = require('fs');

// Load environment variables
try {
  const dotenv = require('dotenv');
  const envPath = path.join(__dirname, '..', '.env');
  if (fs.existsSync(envPath)) {
    dotenv.config({ path: envPath });
  }
} catch (e) {
  // dotenv not available, continue with process.env
}

const dbConfig = {
  host: process.env.DATABASE_HOST || 'localhost',
  port: parseInt(process.env.DATABASE_PORT || '5432', 10),
  user: process.env.DATABASE_USERNAME || 'postgres',
  password: process.env.DATABASE_PASSWORD || '',
  database: process.env.DATABASE || 'auto_tm',
};

// Expected schema based on entities
// Format: { tableName: { columnName: { type: 'expected_type', nullable: true/false } } }
const EXPECTED_SCHEMA = {
  photo_posts: {
    id: { type: 'bigint', nullable: false, primary: true },
    postId: { type: 'varchar', nullable: true, fk: 'posts.uuid' },
    photoUuid: { type: 'varchar', nullable: true, fk: 'photo.uuid' },  // NOT 'uuid'!
  },
  photo_vlogs: {
    id: { type: 'bigint', nullable: false, primary: true },
    vlogId: { type: 'varchar', nullable: true, fk: 'vlogs.uuid' },
    photoUuid: { type: 'varchar', nullable: true, fk: 'photo.uuid' },  // NOT 'uuid'!
  },
  brands_user: {
    id: { type: 'bigint', nullable: false, primary: true },
    userId: { type: 'varchar', nullable: true, fk: 'users.uuid' },
    brandId: { type: 'varchar', nullable: true, fk: 'brands.uuid' },  // NOT 'uuid'!
  },
  posts: {
    uuid: { type: 'varchar', nullable: false, primary: true },
    brandsId: { type: 'varchar', nullable: true, fk: 'brands.uuid' },
    modelsId: { type: 'varchar', nullable: true, fk: 'models.uuid' },
    categoryId: { type: 'varchar', nullable: true, fk: 'categories.uuid' },
    subscriptionId: { type: 'varchar', nullable: true, fk: 'subscriptions.uuid' },
    userId: { type: 'varchar', nullable: true, fk: 'users.uuid' },
    enginePower: { type: 'double precision', nullable: true },
    milleage: { type: 'double precision', nullable: true },
    originalPrice: { type: 'double precision', nullable: true },
    price: { type: 'double precision', nullable: true },
  },
  convert_prices: {
    id: { type: 'bigint', nullable: false, primary: true },
    label: { type: 'varchar', nullable: false, unique: true },
    rate: { type: 'numeric', nullable: false },
  },
};

const client = new Client(dbConfig);

async function getTableColumns(tableName) {
  const res = await client.query(`
    SELECT 
      column_name,
      data_type,
      is_nullable,
      column_default
    FROM information_schema.columns 
    WHERE table_schema = 'public' 
      AND table_name = $1
    ORDER BY ordinal_position
  `, [tableName]);
  
  return res.rows.reduce((acc, row) => {
    acc[row.column_name] = {
      type: row.data_type,
      nullable: row.is_nullable === 'YES',
      default: row.column_default,
    };
    return acc;
  }, {});
}

async function validateSchema() {
  let errors = 0;
  let warnings = 0;

  console.log('🔍 Validating entity-schema alignment...\n');

  for (const [tableName, expectedColumns] of Object.entries(EXPECTED_SCHEMA)) {
    console.log(`📋 Table: ${tableName}`);
    
    try {
      const actualColumns = await getTableColumns(tableName);
      
      if (Object.keys(actualColumns).length === 0) {
        console.log(`   ❌ Table does not exist!\n`);
        errors++;
        continue;
      }

      for (const [colName, expected] of Object.entries(expectedColumns)) {
        const actual = actualColumns[colName];
        
        if (!actual) {
          console.log(`   ❌ Missing column: ${colName}`);
          errors++;
          continue;
        }

        // Type check (simplified)
        const typeMatch = actual.type.includes(expected.type.split(' ')[0]) ||
                         (expected.type === 'varchar' && actual.type === 'character varying') ||
                         (expected.type === 'bigint' && actual.type === 'bigint');
        
        if (!typeMatch) {
          console.log(`   ⚠️  ${colName}: type mismatch (expected: ${expected.type}, got: ${actual.type})`);
          warnings++;
        }
      }

      // Check for extra columns in DB not in expected schema
      const expectedColNames = new Set(Object.keys(expectedColumns));
      const extraCols = Object.keys(actualColumns).filter(c => 
        !expectedColNames.has(c) && !['createdAt', 'updatedAt'].includes(c)
      );
      
      if (extraCols.length > 0) {
        console.log(`   ℹ️  Extra columns in DB: ${extraCols.join(', ')}`);
      }

      console.log(`   ✅ Validated\n`);
    } catch (err) {
      console.log(`   ❌ Error: ${err.message}\n`);
      errors++;
    }
  }

  return { errors, warnings };
}

async function main() {
  try {
    await client.connect();
    console.log('✓ Connected to database\n');

    const { errors, warnings } = await validateSchema();

    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    if (errors === 0 && warnings === 0) {
      console.log('✅ All entities match database schema!');
      process.exit(0);
    } else if (errors === 0) {
      console.log(`⚠️  Validation passed with ${warnings} warning(s)`);
      process.exit(0);
    } else {
      console.log(`❌ Validation failed: ${errors} error(s), ${warnings} warning(s)`);
      console.log('\nFix these issues before deployment!');
      process.exit(1);
    }
  } catch (err) {
    console.error('Error:', err.message);
    process.exit(1);
  } finally {
    await client.end();
  }
}

main();
