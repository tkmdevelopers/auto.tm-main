#!/usr/bin/env node
/**
 * Fix Users Table Schema
 * 
 * This script adds missing columns to the users table if they don't exist.
 * Run this if the migration was marked as executed but columns are missing.
 * 
 * Usage:
 *   node scripts/fix-users-schema.js
 */

const { Sequelize } = require('sequelize');
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
  username: process.env.DATABASE_USERNAME || 'postgres',
  password: process.env.DATABASE_PASSWORD || '',
  database: process.env.DATABASE || 'alpha_motors',
};

if (!dbConfig.password) {
  console.error('ERROR: DATABASE_PASSWORD environment variable is required');
  process.exit(1);
}

const sequelize = new Sequelize(dbConfig.database, dbConfig.username, dbConfig.password, {
  host: dbConfig.host,
  port: dbConfig.port,
  dialect: 'postgres',
  logging: false,
});

async function fixUsersTable() {
  try {
    await sequelize.authenticate();
    console.log('✓ Connected to database');

    const queryInterface = sequelize.getQueryInterface();
    
    // Check if users table exists
    const tables = await queryInterface.showAllTables();
    if (!tables.includes('users')) {
      console.error('ERROR: users table does not exist. Please run migrations first.');
      process.exit(1);
    }

    console.log('✓ users table exists');

    // Get current table structure
    const tableDescription = await queryInterface.describeTable('users');
    console.log('Current columns:', Object.keys(tableDescription).join(', '));

    const columnsToAdd = {};
    let hasChanges = false;

    // Check and fix email column constraint (should be nullable for phone-only auth)
    if (tableDescription.email && tableDescription.email.allowNull === false) {
      console.log('  → Will alter: email column to allow NULL');
      try {
        await queryInterface.changeColumn('users', 'email', {
          type: Sequelize.STRING,
          allowNull: true,
          unique: true,
        });
        console.log('  ✓ Fixed email column constraint');
        hasChanges = true;
      } catch (e) {
        console.error('  ✗ Failed to alter email column:', e.message);
      }
    } else {
      console.log('  ✓ email column is nullable');
    }

    // Check and add location column if missing
    if (!tableDescription.location) {
      columnsToAdd.location = {
        type: Sequelize.STRING,
        allowNull: true,
      };
      console.log('  → Will add: location (STRING, nullable)');
      hasChanges = true;
    } else {
      console.log('  ✓ location column exists');
    }

    // Check and add access column if missing
    if (!tableDescription.access) {
      columnsToAdd.access = {
        type: Sequelize.ARRAY(Sequelize.STRING),
        allowNull: true,
      };
      console.log('  → Will add: access (ARRAY, nullable)');
      hasChanges = true;
    } else {
      console.log('  ✓ access column exists');
    }

    // Check and add firebaseToken column if missing
    if (!tableDescription.firebaseToken) {
      columnsToAdd.firebaseToken = {
        type: Sequelize.STRING,
        allowNull: true,
      };
      console.log('  → Will add: firebaseToken (STRING, nullable)');
      hasChanges = true;
    } else {
      console.log('  ✓ firebaseToken column exists');
    }

    // Check and update refreshToken column
    if (!tableDescription.refreshToken && tableDescription.refreshToke) {
      console.log('  → Will rename: refreshToke → refreshToken');
      await queryInterface.renameColumn('users', 'refreshToke', 'refreshToken');
      hasChanges = true;
    } else if (!tableDescription.refreshToken) {
      columnsToAdd.refreshToken = {
        type: Sequelize.TEXT,
        allowNull: true,
      };
      console.log('  → Will add: refreshToken (TEXT, nullable)');
      hasChanges = true;
    } else {
      console.log('  ✓ refreshToken column exists');
    }

    // Add all missing columns
    if (Object.keys(columnsToAdd).length > 0) {
      console.log('\nAdding missing columns...');
      for (const [columnName, columnDef] of Object.entries(columnsToAdd)) {
        await queryInterface.addColumn('users', columnName, columnDef);
        console.log(`  ✓ Added column: ${columnName}`);
      }
    }

    if (!hasChanges) {
      console.log('\n✓ All required columns already exist. No changes needed.');
    } else {
      console.log('\n✓ Schema fix completed successfully!');
    }

    // Verify final structure
    const finalDescription = await queryInterface.describeTable('users');
    console.log('\nFinal columns:', Object.keys(finalDescription).join(', '));

  } catch (error) {
    console.error('ERROR:', error.message);
    console.error(error);
    process.exit(1);
  } finally {
    await sequelize.close();
  }
}

fixUsersTable();
