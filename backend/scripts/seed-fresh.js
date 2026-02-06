#!/usr/bin/env node
/**
 * Seed Fresh — one-command database reset + full seed
 *
 * This script:
 *   1. Ensures Docker Postgres is running (docker compose up db -d)
 *   2. Waits for Postgres to be ready
 *   3. Resets the database (undo all migrations — drops all tables)
 *   4. Runs migrations (recreates all tables)
 *   5. Seeds base data (currencies, brands, models) via direct DB
 *   6. Builds the NestJS app
 *   7. Boots the API as a local child process
 *   8. Waits for the API to be ready
 *   9. Runs seed-demo-posts-api.js (300 posts with images, auto-creates user via OTP)
 *  10. Shuts down the API
 *
 * Usage:
 *   npm run db:seed:fresh
 *   or
 *   node scripts/seed-fresh.js
 *
 * WARNING: This DESTROYS all existing data in the database configured in .env
 */

const { execSync, spawn } = require('child_process');
const path = require('path');

const BACKEND_DIR = path.join(__dirname, '..');
const API_URL = process.env.API_BASE
  ? process.env.API_BASE.replace(/\/+$/, '')
  : 'http://localhost:3080/api/v1';
const API_PORT = process.env.PORT || 3080;
const POLL_INTERVAL_MS = 2000;
const POLL_TIMEOUT_MS = 90000; // 90 seconds to allow for build + boot
const PG_TIMEOUT_MS = 60000;  // 60 seconds for Postgres readiness

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function run(cmd, label) {
  console.log(`\n📦 ${label}...`);
  execSync(cmd, { stdio: 'inherit', cwd: BACKEND_DIR });
  console.log(`✓ ${label} done`);
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

/**
 * Ensure Docker Postgres container is running and accepting connections.
 * Uses `docker compose up db -d` (only starts the db service, not api).
 * Then polls with pg_isready or a simple TCP check until Postgres responds.
 */
async function ensurePostgres() {
  console.log('\n📦 Ensuring Docker Postgres is running...');

  // Start only the db service in detached mode
  try {
    execSync('docker compose up db -d', { stdio: 'inherit', cwd: BACKEND_DIR });
  } catch (err) {
    throw new Error(
      'Failed to start Docker Postgres. Is Docker running?\n  ' + err.message,
    );
  }

  // Wait for Postgres to accept connections
  const deadline = Date.now() + PG_TIMEOUT_MS;
  console.log('  Waiting for Postgres to accept connections...');

  while (Date.now() < deadline) {
    try {
      // Try pg_isready first (available if postgres-client is installed)
      execSync(
        'docker compose exec -T db pg_isready -U auto_tm',
        { stdio: 'pipe', cwd: BACKEND_DIR },
      );
      console.log('  ✓ Postgres is ready');
      return;
    } catch {
      // pg_isready failed — Postgres not ready yet
    }
    process.stdout.write('.');
    await sleep(POLL_INTERVAL_MS);
  }

  throw new Error(`Postgres did not become ready within ${PG_TIMEOUT_MS / 1000}s`);
}

async function waitForApi() {
  const url = `${API_URL}/brands?limit=1`;
  const deadline = Date.now() + POLL_TIMEOUT_MS;

  console.log(`  Waiting for API at ${url} ...`);

  while (Date.now() < deadline) {
    try {
      const res = await fetch(url);
      if (res.ok) {
        console.log('  ✓ API is ready');
        return;
      }
    } catch {
      // Server not up yet — keep polling
    }
    process.stdout.write('.');
    await sleep(POLL_INTERVAL_MS);
  }

  throw new Error(`API did not become ready within ${POLL_TIMEOUT_MS / 1000}s`);
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

(async () => {
  const startTime = Date.now();

  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('🔄 SEED FRESH — Full database reset + seed');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('');
  console.log('⚠️  WARNING: This will DESTROY all existing data in the database.');
  console.log('');

  let apiProcess = null;

  try {
    // ------------------------------------------------------------------
    // Phase 1 — Ensure Postgres + Database reset + base seed
    // ------------------------------------------------------------------

    console.log('═══ Phase 1: Docker Postgres + Database Reset + Base Seed ═══');

    // 1-2. Ensure Docker Postgres is running and ready
    await ensurePostgres();

    // 3. Undo all migrations (drop all tables)
    run('npm run db:migrate:undo:all', 'Reset database (undo all migrations)');

    // 4. Run migrations (recreate all tables)
    run('npm run db:migrate', 'Run migrations');

    // 5. Seed base data: currencies + brands/models
    run('npm run db:seed:all', 'Seed currencies, brands & models');

    // ------------------------------------------------------------------
    // Phase 2 — Build + boot API, seed posts via API
    // ------------------------------------------------------------------

    console.log('\n═══ Phase 2: Build + Boot API + Seed Posts ═══');

    // 6. Build the NestJS app
    run('npm run build', 'Build NestJS app');

    // 7. Boot the API as a background child process
    console.log('\n📦 Starting API server...');
    apiProcess = spawn('node', ['dist/main'], {
      cwd: BACKEND_DIR,
      stdio: ['ignore', 'pipe', 'pipe'],
      env: { ...process.env, PORT: String(API_PORT) },
      detached: false,
    });

    // Forward API output with a prefix so it's distinguishable
    apiProcess.stdout.on('data', (data) => {
      const lines = data.toString().trim().split('\n');
      for (const line of lines) {
        console.log(`  [API] ${line}`);
      }
    });
    apiProcess.stderr.on('data', (data) => {
      const lines = data.toString().trim().split('\n');
      for (const line of lines) {
        console.error(`  [API:err] ${line}`);
      }
    });

    // Handle unexpected API crash
    let apiExited = false;
    apiProcess.on('exit', (code) => {
      apiExited = true;
      if (code !== null && code !== 0) {
        console.error(`\n✗ API process exited unexpectedly with code ${code}`);
      }
    });

    // 8. Wait for the API to respond
    await waitForApi();

    if (apiExited) {
      throw new Error('API process exited before seeding could start');
    }

    // 9. Run the demo posts seed script (creates user via OTP, seeds 300 posts)
    console.log('');
    run(
      `node ${path.join(__dirname, 'seed-demo-posts-api.js')}`,
      'Seed demo posts with images (300 posts)',
    );

    // ------------------------------------------------------------------
    // Phase 3 — Shutdown
    // ------------------------------------------------------------------

    console.log('\n═══ Phase 3: Shutdown ═══');

    // 10. Gracefully stop the API
    if (apiProcess && !apiExited) {
      console.log('\n📦 Shutting down API server...');
      apiProcess.kill('SIGTERM');

      // Wait up to 10s for graceful shutdown
      const shutdownDeadline = Date.now() + 10000;
      while (!apiExited && Date.now() < shutdownDeadline) {
        await sleep(500);
      }
      if (!apiExited) {
        console.log('  Forcing shutdown (SIGKILL)...');
        apiProcess.kill('SIGKILL');
      }
      console.log('  ✓ API server stopped');
    }

    // Summary
    const elapsed = ((Date.now() - startTime) / 1000).toFixed(1);
    console.log('');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log(`✅ SEED FRESH completed in ${elapsed}s`);
    console.log('');
    console.log('Your database now has:');
    console.log('  • Currencies (TMT, USD, CNY)');
    console.log('  • Car brands & models (from cars.brands.json)');
    console.log('  • 1 seed user (auto-created via OTP)');
    console.log('  • ~300 demo posts with images (status=true)');
    console.log('');
    console.log('Start the API with: npm run start:dev');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    process.exit(0);
  } catch (err) {
    console.error('');
    console.error('✗ Seed fresh failed:', err.message);

    // Clean up: kill API if still running
    if (apiProcess) {
      try {
        apiProcess.kill('SIGKILL');
      } catch {
        // Already dead
      }
    }

    process.exit(1);
  }
})();
