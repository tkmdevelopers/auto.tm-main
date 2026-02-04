const { Client } = require('pg');
const { v5: uuidv5 } = require('uuid');
const path = require('path');
const fs = require('fs');
const data = require(path.join(__dirname, 'cars.brands.json'));

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
      )}. Run migrations on a fresh DB (recommended: reset DB then run "npm run db:init").`,
    );
  }
}

const UUID_NAMESPACE = uuidv5.URL; // stable built-in namespace

(async () => {
  try {
    await client.connect();
    console.log('✓ Connected to database');

    // Validate schema (seed scripts must NOT create/alter tables)
    await requireColumns('brands', ['uuid', 'name', 'createdAt', 'updatedAt']);
    await requireColumns('models', [
      'uuid',
      'brandId',
      'name',
      'yearstart',
      'yearend',
      'createdAt',
      'updatedAt',
    ]);

    // Insert/upsert data
    console.log('\nInserting brands and models...');
    let brandCount = 0;
    let modelCount = 0;
    let failures = 0;
    
    for (const brand of data) {
      const brandUuid = uuidv5(`brand:${brand.categorySlug}`, UUID_NAMESPACE);

      // Insert brand
      try {
        await client.query(
          `INSERT INTO brands (uuid, name, "createdAt", "updatedAt")
           VALUES ($1, $2, NOW(), NOW())
           ON CONFLICT (uuid) DO UPDATE
             SET name = EXCLUDED.name,
                 "updatedAt" = NOW()`,
          [brandUuid, brand.categorySlug]
        );
        brandCount++;
      } catch (err) {
        console.error(`  ✗ Failed to insert brand ${brand.categorySlug}:`, err.message);
        failures++;
        continue;
      }

      // Insert models
      for (const model of brand.models) {
        try {
          const modelUuid = uuidv5(
            `model:${brand.categorySlug}:${model.categorySlug}`,
            UUID_NAMESPACE,
          );
          await client.query(
            `INSERT INTO models (uuid, "brandId", name, "yearstart", "yearend", "createdAt", "updatedAt")
             VALUES ($1, $2, $3, $4, $5, NOW(), NOW())
             ON CONFLICT (uuid) DO UPDATE
               SET name = EXCLUDED.name,
                   "brandId" = EXCLUDED."brandId",
                   "yearstart" = EXCLUDED."yearstart",
                   "yearend" = EXCLUDED."yearend",
                   "updatedAt" = NOW()`,
            [modelUuid, brandUuid, model.name, model.yearStart, model.yearEnd]
          );
          modelCount++;
        } catch (err) {
          console.error(`  ✗ Failed to insert model ${model.name}:`, err.message);
          failures++;
        }
      }
    }

    console.log(`\n✓ Brands and models inserted successfully!`);
    console.log(`  - Brands: ${brandCount}`);
    console.log(`  - Models: ${modelCount}`);

    if (failures > 0) {
      console.error(`\n✗ Car brand/model seeding had ${failures} error(s).`);
      process.exitCode = 1;
    }
  } catch (err) {
    console.error('Error:', err);
    process.exitCode = 1;
  } finally {
    await client.end();
  }
})();
