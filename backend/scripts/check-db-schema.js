#!/usr/bin/env node
/**
 * Check Database Schema
 * 
 * This script connects to the database and shows the actual schema
 * of all tables. Use this to compare with migration expectations.
 * 
 * Usage:
 *   node scripts/check-db-schema.js
 */

const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

// Load environment variables from .env file if it exists
try {
  const dotenv = require('dotenv');
  const envPath = path.join(__dirname, '..', '.env');
  if (fs.existsSync(envPath)) {
    dotenv.config({ path: envPath });
  }
} catch (e) {
  // dotenv not available, continue with process.env
}

// Get database configuration from environment variables
const dbConfig = {
  host: process.env.DATABASE_HOST || 'localhost',
  port: parseInt(process.env.DATABASE_PORT || '5432', 10),
  user: process.env.DATABASE_USERNAME || 'postgres',
  password: process.env.DATABASE_PASSWORD || '',
  database: process.env.DATABASE || 'alpha_motors',
};

if (!dbConfig.password) {
  console.error('ERROR: DATABASE_PASSWORD environment variable is required');
  process.exit(1);
}

const client = new Client({
  host: dbConfig.host,
  port: dbConfig.port,
  user: dbConfig.user,
  password: dbConfig.password,
  database: dbConfig.database,
});

async function checkSchema() {
  try {
    await client.connect();
    console.log('✓ Connected to database\n');

    // Get all tables
    const tablesResult = await client.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_type = 'BASE TABLE'
      ORDER BY table_name;
    `);

    const tables = tablesResult.rows.map(r => r.table_name);
    console.log(`Found ${tables.length} tables:\n`);

    // Check each table's columns
    for (const tableName of tables) {
      const columnsResult = await client.query(`
        SELECT 
          column_name,
          data_type,
          character_maximum_length,
          is_nullable,
          column_default
        FROM information_schema.columns
        WHERE table_schema = 'public' 
        AND table_name = $1
        ORDER BY ordinal_position;
      `, [tableName]);

      console.log(`━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`);
      console.log(`Table: ${tableName}`);
      console.log(`Columns (${columnsResult.rows.length}):`);
      
      if (columnsResult.rows.length === 0) {
        console.log('  (no columns found)');
      } else {
        columnsResult.rows.forEach(col => {
          const nullable = col.is_nullable === 'YES' ? 'NULL' : 'NOT NULL';
          const length = col.character_maximum_length ? `(${col.character_maximum_length})` : '';
          const defaultVal = col.column_default ? ` DEFAULT ${col.column_default}` : '';
          console.log(`  - ${col.column_name}: ${col.data_type}${length} ${nullable}${defaultVal}`);
        });
      }
      console.log('');
    }

    // Check for specific issues
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('Schema Issues Check:\n');

    // Check brands table
    if (tables.includes('brands')) {
      const brandsCols = await client.query(`
        SELECT column_name FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'brands';
      `);
      const brandColumnNames = brandsCols.rows.map(r => r.column_name);
      
      console.log('Brands table:');
      console.log(`  Current columns: ${brandColumnNames.join(', ')}`);
      
      const expectedColumns = ['uuid', 'name', 'location', 'createdAt', 'updatedAt'];
      const missingColumns = expectedColumns.filter(col => !brandColumnNames.includes(col));
      
      if (missingColumns.length > 0) {
        console.log(`  ⚠️  Missing columns: ${missingColumns.join(', ')}`);
      } else {
        console.log('  ✓ All expected columns present');
      }
    } else {
      console.log('  ⚠️  Brands table does not exist');
    }

    // Check convert_prices constraints needed for ON CONFLICT(label)
    if (tables.includes('convert_prices')) {
      const cols = await client.query(
        `
        SELECT column_name, is_nullable
        FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'convert_prices';
        `,
      );
      const byName = new Map(cols.rows.map((r) => [r.column_name, r.is_nullable]));

      console.log('\nConvert prices table:');
      console.log(`  label nullable: ${byName.get('label') || '(missing)'}`);
      console.log(`  rate nullable: ${byName.get('rate') || '(missing)'}`);

      const idx = await client.query(
        `
        SELECT indexname, indexdef
        FROM pg_indexes
        WHERE schemaname = 'public' AND tablename = 'convert_prices';
        `,
      );
      const hasUniqueLabel = idx.rows.some((r) => {
        const def = String(r.indexdef || '').toLowerCase();
        return def.includes('unique') && def.includes('(label)');
      });
      console.log(`  label unique index: ${hasUniqueLabel ? 'YES' : 'NO'}`);
    }

    // Check users table
    if (tables.includes('users')) {
      const usersCols = await client.query(`
        SELECT column_name FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'users';
      `);
      const userColumnNames = usersCols.rows.map(r => r.column_name);
      
      console.log('\nUsers table:');
      console.log(`  Current columns: ${userColumnNames.join(', ')}`);
      
      const expectedColumns = ['uuid', 'name', 'email', 'phone', 'location', 'status', 'role'];
      const missingColumns = expectedColumns.filter(col => !userColumnNames.includes(col));
      
      if (missingColumns.length > 0) {
        console.log(`  ⚠️  Missing columns: ${missingColumns.join(', ')}`);
      } else {
        console.log('  ✓ All expected columns present');
      }
    }

  } catch (error) {
    console.error('ERROR:', error.message);
    console.error(error);
    process.exit(1);
  } finally {
    await client.end();
  }
}

checkSchema();
