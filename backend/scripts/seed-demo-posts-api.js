#!/usr/bin/env node
/**
 * Seed Demo Posts via API
 *
 * Generates ~300 realistic car listing posts with multiple images by calling
 * the running NestJS API.  Templates are defined in seed-data/demo-posts.json;
 * the script multiplies them with varied prices/years/mileage to reach the
 * target count.  Images cycle from the sample-images/ pool.
 *
 * All seeded posts are set to status=true (approved) for frontend testing.
 *
 * Prerequisites:
 *   1. npm run db:init          (migrations + currencies/brands/models)
 *   2. npm run start:dev        (API running on API_BASE)
 *   3. node scripts/seed-demo-posts-api.js
 *
 * Environment variables (all optional — sensible defaults provided):
 *   API_BASE          – default http://localhost:3080/api/v1
 *   SEED_PHONE        – test phone number (default +99361999999)
 *   SEED_TAG          – tag embedded in post descriptions for cleanup
 *   SEED_COUNT        – number of posts to generate (default 300)
 *   SEED_CONCURRENCY  – parallel uploads (default 5)
 */

const path = require('path');
const fs = require('fs');
const { v5: uuidv5 } = require('uuid');
const sharp = require('sharp');

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------

const API_BASE = (process.env.API_BASE || 'http://localhost:3080/api/v1').replace(/\/+$/, '');
const SEED_PHONE = process.env.SEED_PHONE || '+99361999999';
const SEED_TAG = process.env.SEED_TAG || '[seed:demo-posts]';
const SEED_COUNT = parseInt(process.env.SEED_COUNT || '300', 10);
const CONCURRENCY = parseInt(process.env.SEED_CONCURRENCY || '5', 10);
const UUID_NAMESPACE = uuidv5.URL; // same namespace used in dumpCarBrands.js

const FIXTURES_PATH = path.join(__dirname, 'seed-data', 'demo-posts.json');
const IMAGES_DIR = path.join(__dirname, 'sample-images');

// Server multer limit is 5 MB — target 4.5 MB to leave headroom
const MAX_UPLOAD_BYTES = 4.5 * 1024 * 1024;

// Locations for variety
const LOCATIONS = ['Aşgabat', 'Mary', 'Türkmenbaşy', 'Daşoguz', 'Türkmenabat', 'Balkanabat'];

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/** Minimal fetch wrapper that throws on non-2xx */
async function apiFetch(urlPath, opts = {}) {
  const url = `${API_BASE}${urlPath}`;
  const res = await fetch(url, {
    ...opts,
    headers: {
      ...(opts.body && !(opts.body instanceof FormData) ? { 'Content-Type': 'application/json' } : {}),
      ...opts.headers,
    },
  });
  let body;
  const ct = res.headers.get('content-type') || '';
  if (ct.includes('application/json')) {
    body = await res.json();
  } else {
    body = await res.text();
  }
  if (!res.ok) {
    const msg = typeof body === 'object' ? JSON.stringify(body) : body;
    throw new Error(`API ${opts.method || 'GET'} ${urlPath} → ${res.status}: ${msg}`);
  }
  return body;
}

function authHeaders(token) {
  return { Authorization: `Bearer ${token}` };
}

function brandUuid(slug) {
  return uuidv5(`brand:${slug}`, UUID_NAMESPACE);
}

function modelUuid(brandSlug, modelSlug) {
  return uuidv5(`model:${brandSlug}:${modelSlug}`, UUID_NAMESPACE);
}

/** Run async tasks with a concurrency limit */
async function parallelMap(items, concurrency, fn) {
  const results = new Array(items.length);
  let nextIdx = 0;

  async function worker() {
    while (nextIdx < items.length) {
      const idx = nextIdx++;
      results[idx] = await fn(items[idx], idx);
    }
  }

  const workers = [];
  for (let i = 0; i < Math.min(concurrency, items.length); i++) {
    workers.push(worker());
  }
  await Promise.all(workers);
  return results;
}

// ---------------------------------------------------------------------------
// Generate 300 fixtures from templates
// ---------------------------------------------------------------------------

function generateFixtures(templates, count) {
  // Discover all uploadable images from the sample-images directory
  const allImages = fs.readdirSync(IMAGES_DIR)
    .filter((f) => /\.(jpg|jpeg|png|webp)$/i.test(f));

  if (allImages.length === 0) {
    throw new Error(`No uploadable images found in ${IMAGES_DIR}`);
  }

  const fixtures = [];
  let imgIdx = 0;

  for (let i = 0; i < count; i++) {
    const tmpl = templates[i % templates.length];

    // Vary numeric fields to make each post unique
    const yearOffset = (i % 5) - 2;                       // -2 .. +2
    const year = Math.max(2018, Math.min(2026, tmpl.year + yearOffset));
    const priceMult = 0.8 + (((i * 7) % 40) / 100);      // 0.80 .. 1.19
    const price = Math.round(tmpl.price * priceMult);
    const milleage = Math.max(0, tmpl.milleage + (i % 20) * 2500 - 15000);
    const location = LOCATIONS[i % LOCATIONS.length];

    // Pick 2-4 images, cycling through the full pool
    const numImages = 2 + (i % 3);  // 2, 3, or 4
    const images = [];
    for (let j = 0; j < numImages; j++) {
      images.push(allImages[imgIdx % allImages.length]);
      imgIdx++;
    }

    fixtures.push({
      brandSlug: tmpl.brandSlug,
      modelSlug: tmpl.modelSlug,
      year,
      engineType: tmpl.engineType,
      transmission: tmpl.transmission,
      condition: i % 3 === 0 ? 'New' : 'Used',
      enginePower: tmpl.enginePower,
      milleage,
      vin: `SEED-${tmpl.brandSlug.toUpperCase().slice(0, 3)}-${String(i).padStart(4, '0')}`,
      price,
      currency: tmpl.currency,
      credit: i % 4 !== 0,
      exchange: i % 3 !== 0,
      location,
      phone: tmpl.phone,
      personalInfo: {
        name: tmpl.personalInfo.name,
        location,
        region: tmpl.personalInfo.region,
      },
      description: `${year} ${tmpl.brandSlug} ${tmpl.modelSlug} — ${tmpl.description.split('—')[1] || tmpl.description} ${SEED_TAG}`,
      images,
    });
  }

  return fixtures;
}

// ---------------------------------------------------------------------------
// Step A — Pre-flight: ensure brands exist
// ---------------------------------------------------------------------------

async function preflight() {
  console.log('  Checking that brands are seeded...');
  try {
    const brands = await apiFetch('/brands?limit=1');
    if (!brands || (Array.isArray(brands) && brands.length === 0)) {
      throw new Error('No brands found');
    }
  } catch (err) {
    console.error('✗ Pre-flight failed. Have you run "npm run db:seed:all" first?');
    console.error('  Error:', err.message);
    process.exit(1);
  }
  console.log('  ✓ Brands exist in database');
}

// ---------------------------------------------------------------------------
// Step B — OTP login to get access token
// ---------------------------------------------------------------------------

async function login() {
  console.log(`  Logging in with test phone ${SEED_PHONE}...`);

  // Send OTP (POST with JSON body)
  await apiFetch('/otp/send', {
    method: 'POST',
    body: JSON.stringify({ phone: SEED_PHONE }),
  });

  // Verify OTP (test numbers always accept 12345)
  const verifyRes = await apiFetch('/otp/verify', {
    method: 'POST',
    body: JSON.stringify({ phone: SEED_PHONE, otp: '12345' }),
  });

  if (!verifyRes.accessToken) {
    throw new Error('OTP verify did not return an accessToken: ' + JSON.stringify(verifyRes));
  }

  console.log('  ✓ Logged in, got access token');

  // Set a stable profile for the seed user
  try {
    await apiFetch('/auth', {
      method: 'PUT',
      body: JSON.stringify({ name: 'Auto.tm Demo', location: 'Aşgabat' }),
      headers: authHeaders(verifyRes.accessToken),
    });
  } catch {
    // Non-critical — profile may already be set
  }

  return verifyRes.accessToken;
}

// ---------------------------------------------------------------------------
// Step C — Validate brand↔model mapping (only unique pairs)
// ---------------------------------------------------------------------------

async function validateRefs(fixtures, token) {
  console.log('  Validating brand/model references...');

  const seen = new Set();
  for (const fixture of fixtures) {
    const key = `${fixture.brandSlug}:${fixture.modelSlug}`;
    if (seen.has(key)) continue;
    seen.add(key);

    const bUuid = brandUuid(fixture.brandSlug);
    const mUuid = modelUuid(fixture.brandSlug, fixture.modelSlug);

    // Check brand exists
    try {
      await apiFetch(`/brands/${bUuid}`, { headers: authHeaders(token) });
    } catch (err) {
      throw new Error(
        `Brand "${fixture.brandSlug}" (uuid ${bUuid}) not found in DB. ` +
        `Run "npm run db:seed:brands" first.\n  ${err.message}`,
      );
    }

    // Check model exists and belongs to brand
    let modelData;
    try {
      modelData = await apiFetch(`/models/${mUuid}?brand=true`, {
        headers: authHeaders(token),
      });
    } catch (err) {
      throw new Error(
        `Model "${fixture.modelSlug}" (uuid ${mUuid}) not found in DB. ` +
        `Run "npm run db:seed:brands" first.\n  ${err.message}`,
      );
    }

    const actualBrandId = modelData.brandId || modelData.brand?.uuid;
    if (actualBrandId && actualBrandId !== bUuid) {
      throw new Error(
        `Model "${fixture.modelSlug}" has brandId=${actualBrandId}, ` +
        `expected ${bUuid} (brand "${fixture.brandSlug}"). Data integrity issue.`,
      );
    }

    console.log(`    ✓ ${fixture.brandSlug} / ${fixture.modelSlug}`);
  }
  console.log('  ✓ All brand/model references valid');
}

// ---------------------------------------------------------------------------
// Step D — Cleanup previous seeded posts
// ---------------------------------------------------------------------------

async function cleanup(token) {
  console.log('  Cleaning up previous demo posts...');

  let myPosts;
  try {
    myPosts = await apiFetch('/posts/me', { headers: authHeaders(token) });
  } catch {
    console.log('    No existing posts to clean up');
    return 0;
  }

  if (!Array.isArray(myPosts)) {
    console.log('    No existing posts to clean up');
    return 0;
  }

  const seededPosts = myPosts.filter(
    (p) => p.description && p.description.includes(SEED_TAG),
  );

  if (seededPosts.length === 0) {
    console.log('    No previous demo posts found');
    return 0;
  }

  console.log(`    Found ${seededPosts.length} previous demo post(s), deleting...`);

  // Delete in parallel batches for speed
  await parallelMap(seededPosts, CONCURRENCY, async (post) => {
    // Delete attached photos first
    if (Array.isArray(post.photo)) {
      for (const photo of post.photo) {
        try {
          await apiFetch(`/photo/posts/${photo.uuid}`, {
            method: 'DELETE',
            headers: authHeaders(token),
          });
        } catch {
          // Photo may already be deleted
        }
      }
    }
    // Delete the post
    try {
      await apiFetch(`/posts/${post.uuid}`, {
        method: 'DELETE',
        headers: authHeaders(token),
      });
    } catch (err) {
      console.warn(`    ⚠ Could not delete post ${post.uuid}: ${err.message}`);
    }
  });

  console.log(`  ✓ Cleaned up ${seededPosts.length} post(s)`);
  return seededPosts.length;
}

// ---------------------------------------------------------------------------
// Step E — Create posts (with concurrency)
// ---------------------------------------------------------------------------

async function createPosts(fixtures, token) {
  console.log(`  Creating ${fixtures.length} demo posts...`);

  let doneCount = 0;

  const created = await parallelMap(fixtures, CONCURRENCY, async (fixture) => {
    const bUuid = brandUuid(fixture.brandSlug);
    const mUuid = modelUuid(fixture.brandSlug, fixture.modelSlug);

    const payload = {
      brandsId: bUuid,
      modelsId: mUuid,
      location: fixture.location,
      phone: fixture.phone,
      condition: fixture.condition,
      transmission: fixture.transmission,
      engineType: fixture.engineType,
      enginePower: fixture.enginePower,
      year: fixture.year,
      credit: fixture.credit,
      exchange: fixture.exchange,
      milleage: fixture.milleage,
      vin: fixture.vin,
      price: fixture.price,
      currency: fixture.currency,
      personalInfo: fixture.personalInfo,
      description: fixture.description,
    };

    const res = await apiFetch('/posts', {
      method: 'POST',
      body: JSON.stringify(payload),
      headers: authHeaders(token),
    });

    if (!res.uuid) {
      throw new Error(`Post creation failed for ${fixture.brandSlug}/${fixture.modelSlug}: ${JSON.stringify(res)}`);
    }

    doneCount++;
    if (doneCount % 25 === 0 || doneCount === fixtures.length) {
      console.log(`    ... ${doneCount}/${fixtures.length} posts created`);
    }

    return {
      uuid: res.uuid,
      fixture,
      brandUuid: bUuid,
      modelUuid: mUuid,
    };
  });

  console.log(`  ✓ Created ${created.length} post(s)`);
  return created;
}

// ---------------------------------------------------------------------------
// Step E2 — Set status=true on all created posts
// ---------------------------------------------------------------------------

async function approveAll(createdPosts, token) {
  console.log(`  Setting status=true on ${createdPosts.length} posts...`);

  let doneCount = 0;

  await parallelMap(createdPosts, CONCURRENCY, async (entry) => {
    await apiFetch(`/posts/${entry.uuid}`, {
      method: 'PUT',
      body: JSON.stringify({ status: true }),
      headers: authHeaders(token),
    });
    doneCount++;
    if (doneCount % 50 === 0 || doneCount === createdPosts.length) {
      console.log(`    ... ${doneCount}/${createdPosts.length} approved`);
    }
  });

  console.log('  ✓ All posts approved (status=true)');
}

// ---------------------------------------------------------------------------
// Image pre-processing — downscale oversized images so they fit under the
// server's 5 MB multer limit.  We cache processed buffers by filename so each
// image is only compressed once even though it may be reused across many posts.
// ---------------------------------------------------------------------------

const imageCache = new Map();

async function prepareImage(srcPath) {
  if (imageCache.has(srcPath)) {
    return imageCache.get(srcPath);
  }

  const raw = fs.readFileSync(srcPath);
  let result;
  if (raw.length <= MAX_UPLOAD_BYTES) {
    result = { buffer: raw, ext: path.extname(srcPath).toLowerCase() };
  } else {
    const processed = await sharp(raw)
      .resize({ width: 1920, withoutEnlargement: true })
      .jpeg({ quality: 80 })
      .toBuffer();
    result = { buffer: processed, ext: '.jpg' };
  }

  imageCache.set(srcPath, result);
  return result;
}

// ---------------------------------------------------------------------------
// Step F — Upload images for each post (with concurrency)
// ---------------------------------------------------------------------------

async function uploadImages(createdPosts, token) {
  console.log(`  Uploading images for ${createdPosts.length} posts...`);

  // Pre-warm the image cache so all 33 images are processed once upfront
  const allImageNames = [...new Set(createdPosts.flatMap((e) => e.fixture.images || []))];
  console.log(`    Pre-processing ${allImageNames.length} unique images...`);
  for (const name of allImageNames) {
    const imgPath = path.join(IMAGES_DIR, name);
    if (fs.existsSync(imgPath)) {
      await prepareImage(imgPath);
    }
  }
  console.log('    ✓ Image cache ready');

  let doneCount = 0;

  await parallelMap(createdPosts, CONCURRENCY, async (entry) => {
    const imageFiles = (entry.fixture.images || [])
      .map((name) => path.join(IMAGES_DIR, name))
      .filter((p) => fs.existsSync(p));

    if (imageFiles.length === 0) {
      entry.imageCount = 0;
      return;
    }

    const formData = new FormData();
    formData.append('uuid', entry.uuid);

    for (const imgPath of imageFiles) {
      const { buffer, ext } = await prepareImage(imgPath);
      const baseName = path.basename(imgPath, path.extname(imgPath));
      const fileName = `${baseName}${ext}`;
      const mimeMap = { '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.png': 'image/png', '.webp': 'image/webp' };
      const mime = mimeMap[ext] || 'image/jpeg';
      const blob = new Blob([buffer], { type: mime });
      formData.append('files', blob, fileName);
    }

    await apiFetch('/photo/posts', {
      method: 'PUT',
      body: formData,
      headers: authHeaders(token),
    });

    entry.imageCount = imageFiles.length;
    doneCount++;
    if (doneCount % 25 === 0 || doneCount === createdPosts.length) {
      console.log(`    ... ${doneCount}/${createdPosts.length} posts with images`);
    }
  });

  console.log('  ✓ All images uploaded');
}

// ---------------------------------------------------------------------------
// Step G — Spot-check verification (sample 10 posts, not all 300)
// ---------------------------------------------------------------------------

async function verify(createdPosts) {
  const sampleSize = Math.min(10, createdPosts.length);
  console.log(`  Spot-checking ${sampleSize} random posts...`);

  let allGood = true;

  // Pick evenly spaced samples
  const step = Math.floor(createdPosts.length / sampleSize);
  for (let i = 0; i < sampleSize; i++) {
    const entry = createdPosts[i * step];
    const post = await apiFetch(`/posts/${entry.uuid}?photo=true&brand=true&model=true`);

    const errors = [];

    if (post.brandsId !== entry.brandUuid) {
      errors.push(`brandsId mismatch: got ${post.brandsId}, expected ${entry.brandUuid}`);
    }
    if (post.modelsId !== entry.modelUuid) {
      errors.push(`modelsId mismatch: got ${post.modelsId}, expected ${entry.modelUuid}`);
    }
    if (post.status !== true) {
      errors.push(`status is ${post.status}, expected true`);
    }

    const photoCount = Array.isArray(post.photo) ? post.photo.length : 0;
    if (photoCount !== (entry.imageCount || 0)) {
      errors.push(`photo count: got ${photoCount}, expected ${entry.imageCount}`);
    }

    if (Array.isArray(post.photo)) {
      for (const photo of post.photo) {
        if (!photo.path || !photo.path.small || !photo.path.medium || !photo.path.large) {
          errors.push(`photo ${photo.uuid} missing resized variants`);
        }
      }
    }

    if (errors.length > 0) {
      console.error(`    ✗ Post ${entry.uuid}: ${errors.join('; ')}`);
      allGood = false;
    } else {
      console.log(
        `    ✓ Post #${i * step + 1} — ` +
        `${entry.fixture.brandSlug} ${entry.fixture.modelSlug}, ` +
        `photos=${photoCount}, status=true`,
      );
    }
  }

  if (allGood) {
    console.log(`  ✓ All ${sampleSize} spot-checks passed`);
  } else {
    console.error('  ⚠ Some posts had verification issues (see above)');
  }

  return allGood;
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

(async () => {
  const startTime = Date.now();

  console.log('🌱 Seed Demo Posts via API');
  console.log(`   API:         ${API_BASE}`);
  console.log(`   Phone:       ${SEED_PHONE}`);
  console.log(`   Tag:         ${SEED_TAG}`);
  console.log(`   Target:      ${SEED_COUNT} posts`);
  console.log(`   Concurrency: ${CONCURRENCY}`);
  console.log('');

  // Load templates
  if (!fs.existsSync(FIXTURES_PATH)) {
    console.error(`✗ Fixtures file not found: ${FIXTURES_PATH}`);
    process.exit(1);
  }
  const templates = JSON.parse(fs.readFileSync(FIXTURES_PATH, 'utf-8'));
  console.log(`Loaded ${templates.length} template(s) from ${path.basename(FIXTURES_PATH)}`);

  // Generate full fixture list
  const fixtures = generateFixtures(templates, SEED_COUNT);
  console.log(`Generated ${fixtures.length} fixture(s)\n`);

  try {
    // A — Pre-flight
    console.log('[A] Pre-flight checks');
    await preflight();
    console.log('');

    // B — Login
    console.log('[B] Authentication');
    const token = await login();
    console.log('');

    // C — Validate references (only unique brand/model pairs from templates)
    console.log('[C] Validate brand/model references');
    await validateRefs(templates, token);
    console.log('');

    // D — Cleanup
    console.log('[D] Cleanup previous demo posts');
    await cleanup(token);
    console.log('');

    // E — Create posts
    console.log('[E] Create posts');
    const createdPosts = await createPosts(fixtures, token);
    console.log('');

    // E2 — Approve all posts (status=true)
    console.log('[E2] Approve posts');
    await approveAll(createdPosts, token);
    console.log('');

    // F — Upload images
    console.log('[F] Upload images');
    await uploadImages(createdPosts, token);
    console.log('');

    // G — Verify
    console.log('[G] Verification (spot-check)');
    const ok = await verify(createdPosts);
    console.log('');

    // Summary
    const elapsed = ((Date.now() - startTime) / 1000).toFixed(1);
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log(`✅ Seeded ${createdPosts.length} demo post(s) with images in ${elapsed}s`);
    console.log(`   All posts have status=true`);

    // Brand/model breakdown
    const breakdown = {};
    for (const entry of createdPosts) {
      const key = `${entry.fixture.brandSlug} ${entry.fixture.modelSlug}`;
      breakdown[key] = (breakdown[key] || 0) + 1;
    }
    console.log('\n   Breakdown by brand/model:');
    for (const [key, count] of Object.entries(breakdown).sort((a, b) => b[1] - a[1])) {
      console.log(`     ${key}: ${count}`);
    }

    const totalPhotos = createdPosts.reduce((n, e) => n + (e.imageCount || 0), 0);
    console.log(`\n   Total photos: ${totalPhotos}`);

    process.exit(ok ? 0 : 1);
  } catch (err) {
    console.error('');
    console.error('✗ Seeding failed:', err.message);
    if (err.stack) {
      console.error(err.stack.split('\n').slice(1, 4).join('\n'));
    }
    process.exit(1);
  }
})();
