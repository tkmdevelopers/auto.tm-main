const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

// Load environment variables from .env file if it exists
try {
  const dotenv = require('dotenv');
  const envPath = path.join(__dirname, '.env');
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
  console.error('Please set it in your .env file or environment');
  process.exit(1);
}

const client = new Client({
  host: dbConfig.host,
  port: dbConfig.port,
  user: dbConfig.user,
  password: dbConfig.password,
  database: dbConfig.database,
});

async function requireColumns(table, requiredColumns) {
  const res = await client.query(
    `
    SELECT column_name
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = $1
    `,
    [table],
  );
  const cols = new Set(res.rows.map((r) => r.column_name));
  const missing = requiredColumns.filter((c) => !cols.has(c));
  if (missing.length) {
    throw new Error(
      `Schema mismatch: table "${table}" is missing column(s): ${missing.join(
        ', ',
      )}. Run migrations on a fresh DB (recommended: reset DB then run \"npm run db:init\").`,
    );
  }
}

// Currency data
// Base currency: TMT (Turkmenistan Manat) = 1.0
// Exchange rates are relative to TMT
const currencies = [
  {
    label: 'TMT',
    rate: 1.0,
    description: 'Turkmenistan Manat (base currency)',
  },
  {
    label: 'USD',
    rate: 19.5,
    description: 'US Dollar (1 USD = 19.5 TMT)',
  },
  {
    label: 'CNY',
    rate: 2.7,
    description: 'Chinese Yuan (1 CNY ≈ 2.7 TMT, calculated: if 1 USD = 19.5 TMT and 1 USD ≈ 7.2 CNY, then 1 CNY ≈ 2.7 TMT)',
  },
];

(async () => {
  try {
    await client.connect();
    console.log('✓ Connected to database');

    // Validate schema (seed scripts must NOT create/alter tables)
    await requireColumns('convert_prices', ['label', 'rate']);

    // Insert/upsert currencies
    console.log('\nInserting currencies...');
    let failed = 0;
    for (const currency of currencies) {
      try {
        await client.query(
          `INSERT INTO convert_prices (label, rate)
           VALUES ($1, $2)
           ON CONFLICT (label) DO UPDATE SET rate = EXCLUDED.rate`,
          [currency.label, currency.rate]
        );
        console.log(`  ✓ ${currency.label}: ${currency.rate} TMT - ${currency.description}`);
      } catch (err) {
        console.error(`  ✗ Failed to insert ${currency.label}:`, err.message);
        failed++;
      }
    }

    // 4️⃣ Verify inserted data
    const result = await client.query('SELECT label, rate FROM convert_prices ORDER BY label');
    console.log('\n✓ Currency dump completed successfully!');
    console.log('\nCurrent currencies in database:');
    result.rows.forEach((row) => {
      console.log(`  - ${row.label}: ${parseFloat(row.rate)} TMT`);
    });

    if (failed > 0) {
      console.error(`\n✗ Currency seeding failed for ${failed} currency(ies).`);
      process.exitCode = 1;
    }
  } catch (err) {
    console.error('Error:', err);
    process.exit(1);
  } finally {
    await client.end();
  }
})();
