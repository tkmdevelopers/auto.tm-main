const { Client } = require('pg');
const { v4: uuidv4 } = require('uuid');
const path = require('path');
const data = require(path.join(__dirname, 'cars.brands.json'));

const client = new Client({
  host: 'localhost',
  port: 5432,
  user: 'postgres',
  password: 'root',
  database: 'alpha_motors'
});

(async () => {
  try {
    await client.connect();

    // 1️⃣ Create brands table if not exists
    await client.query(`
      CREATE TABLE IF NOT EXISTS brands (
        uuid UUID PRIMARY KEY,
        name TEXT NOT NULL,
        "createdAt" TIMESTAMPTZ DEFAULT NOW(),
        "updatedAt" TIMESTAMPTZ DEFAULT NOW()
      );
    `);

    // 2️⃣ Create models table if not exists
    await client.query(`
      CREATE TABLE IF NOT EXISTS models (
        uuid UUID PRIMARY KEY,
        "brandId" UUID REFERENCES brands(uuid) ON DELETE CASCADE,
        name TEXT NOT NULL,
        "yearStart" INT,
        "yearEnd" INT,
        "createdAt" TIMESTAMPTZ DEFAULT NOW(),
        "updatedAt" TIMESTAMPTZ DEFAULT NOW()
      );
    `);

    // 3️⃣ Insert data
    for (const brand of data) {
      const brandUuid = uuidv4(); // Generate UUID for brand

      // Insert brand
      await client.query(
        `INSERT INTO brands (uuid, name, "createdAt", "updatedAt")
         VALUES ($1, $2, NOW(), NOW())`,
        [brandUuid, brand.categorySlug]
      );

      // Insert models
      for (const model of brand.models) {
        const modelUuid = uuidv4(); // Generate UUID for each model
        await client.query(
          `INSERT INTO models (uuid, "brandId", name, "yearStart", "yearEnd", "createdAt", "updatedAt")
           VALUES ($1, $2, $3, $4, $5, NOW(), NOW())`,
          [modelUuid, brandUuid, model.name, model.yearStart, model.yearEnd]
        );
      }
    }

    console.log('Brands and models inserted successfully with UUIDs and year columns!');
  } catch (err) {
    console.error('Error:', err);
  } finally {
    await client.end();
  }
})();
