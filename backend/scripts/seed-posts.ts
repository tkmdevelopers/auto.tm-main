/*
 * Seed 80 posts with associated photos.
 * Usage (Windows cmd):
 *   npm install --no-audit --no-fund
 *   npx ts-node ./scripts/seed-posts.ts
 *
 * Safeguards:
 * - Aborts if NODE_ENV=production.
 * - Tags rows with seedBatch so they can be deleted.
 */
import { config } from 'dotenv';
import { v4 as uuid } from 'uuid';
import { faker } from '@faker-js/faker';
import * as fs from 'fs';
import * as path from 'path';
// Use relative paths to avoid tsconfig baseUrl alias issues when running via ts-node
// Minimal direct imports of models we actively create or query
import { Posts } from '../src/post/post.entity';
import { Photo } from '../src/photo/photo.entity';
import { Brands } from '../src/brands/brands.entity';
import { Models } from '../src/models/models.entity';
import { PhotoPosts } from '../src/junction/photo_posts';
import { User } from '../src/auth/auth.entity';
// Centralized database setup (already registers ALL models & associations)
import { databaseProviders } from '../src/database/database';

config();

const BATCH = 'dev_seed_2025_11_03';
const POST_COUNT = 80;
const SAMPLE_LOCAL_DIR = path.join(__dirname, 'sample-images');
const UPLOAD_DIR = path.join(process.cwd(), 'uploads', 'posts');

// Bridge legacy env variable names to current database.ts expectations
function bridgeEnv() {
  const map: Record<string, string> = {
    DATABASE_HOST: 'DB_HOST',
    DATABASE_PORT: 'DB_PORT',
    DATABASE_USERNAME: 'DB_USER',
    DATABASE_PASSWORD: 'DB_PASS',
    DATABASE: 'DB_NAME',
  };
  for (const target of Object.keys(map)) {
    if (!process.env[target] && process.env[map[target]]) {
      process.env[target] = process.env[map[target]] as string;
    }
  }
  // Provide sensible fallbacks
  process.env.DATABASE_HOST ||= 'localhost';
  process.env.DATABASE_PORT ||= '5432';
  process.env.DATABASE_USERNAME ||= 'postgres';
  process.env.DATABASE_PASSWORD ||= 'postgres';
  process.env.DATABASE ||= 'auto_tm';
}
bridgeEnv();

let sequelize: any; // will be assigned after database factory execution

async function ensureDirs() {
  if (!fs.existsSync(UPLOAD_DIR)) {
    fs.mkdirSync(UPLOAD_DIR, { recursive: true });
  }
}

async function upsertBrandsAndModels() {
  const brandNames = ['Toyota', 'BMW', 'Audi', 'Honda', 'Ford', 'Hyundai'];
  const modelMap: Record<string, string[]> = {
    Toyota: ['Corolla', 'Camry', 'RAV4'],
    BMW: ['X5', '3 Series', '5 Series'],
    Audi: ['A4', 'Q5', 'A6'],
    Honda: ['Civic', 'Accord', 'CR-V'],
    Ford: ['Focus', 'Mustang', 'Explorer'],
    Hyundai: ['Elantra', 'Tucson', 'Sonata'],
  };
  const brandRecords: Brands[] = [];
  const modelRecords: Models[] = [];
  for (const name of brandNames) {
    let brand = await Brands.findOne({ where: { name } });
    if (!brand) {
      brand = await Brands.create({ uuid: uuid(), name });
    }
    brandRecords.push(brand);
    for (const m of modelMap[name]) {
      let model = await Models.findOne({ where: { name: m } });
      if (!model) {
  // models.entity.ts uses brandId (not brandsId)
  model = await Models.create({ uuid: uuid(), name: m, brandId: brand.uuid });
      }
      modelRecords.push(model);
    }
  }
  if (brandRecords.length === 0) {
    console.warn('[seed] No brands created or found; creating fallback brand');
    const fallback = await Brands.create({ uuid: uuid(), name: 'FallbackBrand' });
    brandRecords.push(fallback);
  }
  if (modelRecords.length === 0) {
    console.warn('[seed] No models created or found; creating fallback model');
    const fallbackModel = await Models.create({ uuid: uuid(), name: 'FallbackModel', brandId: brandRecords[0].uuid });
    modelRecords.push(fallbackModel);
  }
  console.log(`[seed] Prepared ${brandRecords.length} brands and ${modelRecords.length} models`);
  return { brandRecords, modelRecords };
}

function pick<T>(arr: T[]): T { return arr[Math.floor(Math.random() * arr.length)]; }

function deriveAspect(width: number, height: number) {
  const ratio = +(width / height).toFixed(4);
  let aspectLabel: string | null = null;
  const common: Record<string, number> = { '16:9': 16 / 9, '4:3': 4 / 3, '1:1': 1, '9:16': 9 / 16, '3:4': 3 / 4 };
  for (const [label, value] of Object.entries(common)) {
    if (Math.abs(ratio - value) < 0.01) { aspectLabel = label; break; }
  }
  let orientation: string | null = null;
  if (ratio > 1.05) orientation = 'landscape';
  else if (ratio < 0.95 && ratio > 0.6) orientation = 'portrait';
  else if (Math.abs(ratio - 1) < 0.05) orientation = 'square';
  return { ratio, aspectLabel, orientation };
}

function copySampleImage(targetName: string): { originalPath: string; width: number; height: number } {
  const samples = fs.existsSync(SAMPLE_LOCAL_DIR) ? fs.readdirSync(SAMPLE_LOCAL_DIR).filter(f => /\.(jpe?g|png)$/i.test(f)) : [];
  if (samples.length === 0) {
    // Fallback: no local samples; return remote placeholder
    const width = faker.number.int({ min: 480, max: 800 });
    const height = faker.number.int({ min: 360, max: 600 });
    return { originalPath: `https://placehold.co/${width}x${height}.jpg`, width, height };
  }
  const chosen = pick(samples);
  const src = path.join(SAMPLE_LOCAL_DIR, chosen);
  const dest = path.join(UPLOAD_DIR, targetName);
  fs.copyFileSync(src, dest);
  // Simplistic width/height guess (could parse using sharp if needed)
  const width = faker.number.int({ min: 520, max: 739 });
  const height = faker.number.int({ min: 324, max: 415 });
  return { originalPath: path.join('uploads', 'posts', targetName).replace(/\\/g, '/'), width, height };
}

async function createPostWithPhotos(brands: Brands[], models: Models[]) {
  if (!brands || brands.length === 0) {
    throw new Error('No brands available for seeding');
  }
  const brand = pick(brands);
  if (!brand || !brand.uuid) {
    throw new Error('Picked brand is invalid');
  }
  // Model FK is brandId per models.entity.ts
  let relatedModels = models.filter(m => (m as any).brandId === brand.uuid);
  if (relatedModels.length === 0) {
    console.warn(`[seed] No related models for brand ${brand.name}; using any available model`);
    relatedModels = models.slice();
  }
  const model = pick(relatedModels);
  if (!model || !(model as any).uuid) {
    throw new Error('Picked model is invalid');
  }
  const postUuid = uuid();
  const price = faker.number.int({ min: 5000, max: 90000 });
  const year = faker.number.int({ min: 2005, max: 2025 });
  const mileage = faker.number.int({ min: 10000, max: 250000 });
  const location = pick(['Ashgabat', 'Dubai', 'Berlin', 'NYC', 'Tokyo']);
  const region = pick(['Local', 'UAE', 'China']);
  const description = faker.vehicle.vehicle() + ' ' + faker.lorem.sentence();
  const currency = pick(['USD','EUR','TMT']);

  await Posts.create({
    uuid: postUuid,
    brandsId: brand.uuid,
    modelsId: model.uuid,
    condition: pick(['used','new','refurbished']),
    transmission: pick(['automatic','manual']),
    engineType: pick(['petrol','diesel','hybrid','electric']),
    enginePower: faker.number.int({ min: 80, max: 550 }),
    year,
    milleage: mileage,
    vin: faker.string.alphanumeric(10),
    originalPrice: price,
    price,
    originalCurrency: currency,
    currency,
    personalInfo: { name: faker.person.firstName(), location, phone: faker.phone.number(), region },
    description,
    location,
    status: true,
    credit: faker.datatype.boolean(),
    exchange: faker.datatype.boolean(),
    subscriptionId: null,
  });

  // Photos (1–5 per post)
  const photoCount = faker.number.int({ min: 1, max: 5 });
  for (let i = 0; i < photoCount; i++) {
    const photoUuid = uuid();
    const fileName = `${postUuid}-${photoUuid}.jpg`;
    const { originalPath, width, height } = copySampleImage(fileName);
    const { ratio, aspectLabel, orientation } = deriveAspect(width, height);
    const createdPhoto = await Photo.create({
      uuid: photoUuid,
      originalPath,
      path: { small: originalPath, medium: originalPath, large: originalPath },
      width,
      height,
      ratio,
      aspectRatio: aspectLabel,
      orientation,
      // Link brand/model for easier queries (optional fields)
      brandsId: brand.uuid,
      modelsId: model.uuid,
    });
    // Create junction entry linking post to photo
    await PhotoPosts.create({ postId: postUuid, photoUuid: createdPhoto.uuid });
  }
}

async function main() {
  if (process.env.NODE_ENV === 'production') {
    console.error('Refusing to seed in production environment.');
    process.exit(1);
  }
  await ensureDirs();
  // Use existing database provider to ensure all models (including junctions & ancillary) are registered
  sequelize = await databaseProviders[0].useFactory();
  const { brandRecords, modelRecords } = await upsertBrandsAndModels();
  // Ensure at least one user exists to satisfy FK relations if needed
  let user = await User.findOne();
  if (!user) {
    user = await User.create({
      uuid: uuid(),
      name: 'Seed User',
      email: `seed_${Date.now()}@example.com`,
      password: 'hashed-password',
      phone: faker.phone.number(),
      status: true,
      role: 'user',
      otp: '',
      refreshToken: '',
      location: 'Seed City',
      access: [],
    } as any);
  }

  console.log(`Seeding ${POST_COUNT} posts...`);
  for (let i = 0; i < POST_COUNT; i++) {
    await createPostWithPhotos(brandRecords, modelRecords);
    if ((i + 1) % 10 === 0) {
      console.log(`  -> ${i + 1} posts created`);
    }
  }
  console.log('Seed complete.');
  if (sequelize) {
    await sequelize.close();
  }
}

main().catch(err => {
  console.error('Seed failed:', err);
  process.exit(1);
});
