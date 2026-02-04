#!/usr/bin/env node
/**
 * Generate config/config.json from environment variables
 * 
 * This script reads database configuration from environment variables
 * and generates a Sequelize-compatible config.json file.
 * 
 * Usage:
 *   node scripts/generate-config.js
 * 
 * Environment variables:
 *   DATABASE_HOST (default: localhost)
 *   DATABASE_PORT (default: 5432)
 *   DATABASE_USERNAME (default: postgres)
 *   DATABASE_PASSWORD (required)
 *   DATABASE (default: alpha_motors)
 */

const fs = require('fs');
const path = require('path');

// Load environment variables from .env file if it exists
const envPath = path.join(__dirname, '..', '.env');
if (fs.existsSync(envPath)) {
  // Read .env file manually if dotenv is not available
  const envContent = fs.readFileSync(envPath, 'utf8');
  envContent.split('\n').forEach(line => {
    const trimmedLine = line.trim();
    // Skip comments and empty lines
    if (trimmedLine && !trimmedLine.startsWith('#')) {
      const equalIndex = trimmedLine.indexOf('=');
      if (equalIndex > 0) {
        const key = trimmedLine.substring(0, equalIndex).trim();
        let value = trimmedLine.substring(equalIndex + 1).trim();
        // Remove quotes if present
        if ((value.startsWith('"') && value.endsWith('"')) || 
            (value.startsWith("'") && value.endsWith("'"))) {
          value = value.slice(1, -1);
        }
        // Only set if not already in process.env (env vars take precedence)
        if (!process.env[key]) {
          process.env[key] = value;
        }
      }
    }
  });
}

// Get database configuration from environment variables
const dbConfig = {
  host: process.env.DATABASE_HOST || 'localhost',
  port: parseInt(process.env.DATABASE_PORT || '5432', 10),
  username: process.env.DATABASE_USERNAME || 'postgres',
  password: process.env.DATABASE_PASSWORD || '',
  database: process.env.DATABASE || 'alpha_motors',
};

// Validate required fields
if (!dbConfig.password) {
  console.error('ERROR: DATABASE_PASSWORD environment variable is required');
  console.error('Please set it in your .env file or environment');
  process.exit(1);
}

// Generate config.json structure
const config = {
  development: {
    username: dbConfig.username,
    password: dbConfig.password,
    database: dbConfig.database,
    host: dbConfig.host,
    port: dbConfig.port,
    dialect: 'postgres',
  },
  test: {
    username: dbConfig.username,
    password: dbConfig.password,
    database: `${dbConfig.database}_test`,
    host: dbConfig.host,
    port: dbConfig.port,
    dialect: 'postgres',
  },
  production: {
    username: dbConfig.username,
    password: dbConfig.password,
    database: dbConfig.database,
    host: dbConfig.host,
    port: dbConfig.port,
    dialect: 'postgres',
  },
};

// Write config.json
const configPath = path.join(__dirname, '..', 'config', 'config.json');
const configDir = path.dirname(configPath);

// Ensure config directory exists
if (!fs.existsSync(configDir)) {
  fs.mkdirSync(configDir, { recursive: true });
}

fs.writeFileSync(configPath, JSON.stringify(config, null, 2));

console.log('✓ Generated config/config.json from environment variables');
console.log(`  Database: ${dbConfig.database}`);
console.log(`  Host: ${dbConfig.host}:${dbConfig.port}`);
console.log(`  Username: ${dbConfig.username}`);
