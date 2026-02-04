#!/usr/bin/env node
/**
 * Master Seed Script
 * 
 * This script runs all seed scripts in the correct order:
 * 1. Currencies (TMT, USD, CNY)
 * 2. Car Brands and Models
 * 
 * Usage:
 *   npm run db:seed:all
 *   or
 *   node scripts/seed-all.js
 */

const { execSync } = require('child_process');
const path = require('path');

console.log('🌱 Starting database seeding...\n');

const scripts = [
  {
    name: 'Currencies',
    file: path.join(__dirname, '..', 'dumpCurrencies.js'),
  },
  {
    name: 'Car Brands & Models',
    file: path.join(__dirname, '..', 'dumpCarBrands.js'),
  },
];

let successCount = 0;
let failCount = 0;

for (const script of scripts) {
  try {
    console.log(`📦 Seeding ${script.name}...`);
    execSync(`node "${script.file}"`, {
      stdio: 'inherit',
      cwd: path.join(__dirname, '..'),
    });
    console.log(`✓ ${script.name} seeded successfully\n`);
    successCount++;
  } catch (error) {
    console.error(`✗ Failed to seed ${script.name}:`, error.message);
    console.error('');
    failCount++;
    // Continue with other scripts even if one fails
  }
}

console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
if (failCount === 0) {
  console.log(`✅ All seed scripts completed successfully! (${successCount}/${scripts.length})`);
  process.exit(0);
} else {
  console.log(`⚠️  Seeding completed with errors (${successCount} succeeded, ${failCount} failed)`);
  process.exit(1);
}
