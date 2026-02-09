#!/usr/bin/env node
/**
 * Test Filter Flow & Brands History
 *
 * Validates:
 * 1. POST /api/v1/brands/history (fix verification)
 * 2. GET /api/v1/posts with complex filters (color, enginePower, credit, exchange, etc.)
 */

const API_BASE = 'http://localhost:3080/api/v1';

async function main() {
  console.log('🚀 Starting Filter Flow Verification...');

  // -------------------------------------------------------------------------
  // 1. Verify POST /brands/history (The 404 Fix)
  // -------------------------------------------------------------------------
  console.log('\n--- 1. Testing POST /brands/history ---');
  
  // First, get some brand UUIDs to query
  let uuids = [];
  try {
    const brandsRes = await fetch(`${API_BASE}/brands?limit=3`);
    if (!brandsRes.ok) throw new Error(`Failed to fetch brands: ${brandsRes.status}`);
    const brandsData = await brandsRes.json();
    uuids = brandsData.data ? brandsData.data.map(b => b.uuid) : brandsData.map(b => b.uuid);
  } catch (e) {
    console.error('Failed to fetch brands list:', e.message);
    process.exit(1);
  }
  
  if (uuids.length === 0) {
    console.warn('⚠️ No brands found to test history endpoint.');
  } else {
    console.log(`Found ${uuids.length} brands to query history for.`);
    
    const historyRes = await fetch(`${API_BASE}/brands/history`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ uuids, post: false }),
    });

    if (historyRes.ok) {
      const historyData = await historyRes.json();
      console.log(`✅ POST /brands/history successful. Returned ${historyData.length} items.`);
    } else {
      console.error(`❌ POST /brands/history failed: ${historyRes.status} ${historyRes.statusText}`);
      const err = await historyRes.text();
      console.error(err);
      process.exit(1);
    }
  }

  // -------------------------------------------------------------------------
  // 2. Verify Filter Logic
  // -------------------------------------------------------------------------
  console.log('\n--- 2. Testing Post Filters ---');

  // Fetch a sample post to use as a baseline for filtering
  let sample;
  try {
    const sampleRes = await fetch(`${API_BASE}/posts?limit=1`);
    if (!sampleRes.ok) throw new Error('Failed to fetch sample post');
    const sampleJson = await sampleRes.json();
    sample = Array.isArray(sampleJson) ? sampleJson[0] : sampleJson.data?.[0];
  } catch (e) {
    console.error('Failed to fetch sample post:', e.message);
    process.exit(1);
  }

  if (!sample) {
    console.error('⚠️ No posts found in DB. Cannot verify filters.');
    console.log('Suggestion: Run `npm run db:seed:fresh` to populate data.');
    process.exit(0);
  }

  console.log('Baseline Post:', {
    uuid: sample.uuid,
    price: sample.price,
    year: sample.year,
    color: sample.color,
    credit: sample.credit,
    exchange: sample.exchange,
    enginePower: sample.enginePower,
  });

  // Test: Color Filter (if sample has color)
  if (sample.color) {
    console.log(`\nTesting Color Filter: ${sample.color}`);
    const colorRes = await fetch(`${API_BASE}/posts?color=${encodeURIComponent(sample.color)}`);
    const colorData = await colorRes.json();
    const hits = Array.isArray(colorData) ? colorData : colorData.data;
    const match = hits.find(p => p.uuid === sample.uuid);
    
    if (match) console.log(`✅ Found baseline post when filtering by color=${sample.color}`);
    else console.error(`❌ Baseline post NOT found when filtering by color=${sample.color}`);
  } else {
    console.log('\n⚠️ Baseline post has no color. Skipping color filter test.');
  }

  // Test: Price Range
  const minP = Math.floor(sample.price * 0.9);
  const maxP = Math.ceil(sample.price * 1.1);
  console.log(`\nTesting Price Range: ${minP} - ${maxP}`);
  const priceRes = await fetch(`${API_BASE}/posts?minPrice=${minP}&maxPrice=${maxP}`);
  const priceData = await priceRes.json();
  const priceHits = Array.isArray(priceData) ? priceData : priceData.data;
  if (priceHits.find(p => p.uuid === sample.uuid)) {
    console.log('✅ Found baseline post in price range.');
  } else {
    console.error('❌ Baseline post missing from price range results.');
  }

  // Test: Credit (Boolean)
  const creditVal = sample.credit ? 'true' : 'false';
  console.log(`\nTesting Credit: ${creditVal}`);
  const creditRes = await fetch(`${API_BASE}/posts?credit=${creditVal}`);
  const creditData = await creditRes.json();
  const creditHits = Array.isArray(creditData) ? creditData : creditData.data;
  // Ensure all results match the credit value (or at least our sample is there)
  if (creditHits.find(p => p.uuid === sample.uuid)) {
    console.log(`✅ Found baseline post with credit=${creditVal}.`);
  } else {
    console.error(`❌ Baseline post missing with credit=${creditVal}.`);
  }

  // Test: Engine Power (gte)
  if (sample.enginePower) {
    const minPower = sample.enginePower - 0.1; // Should include our post
    console.log(`\nTesting Engine Power >= ${minPower}`);
    const powerRes = await fetch(`${API_BASE}/posts?enginePower=${minPower}`);
    const powerData = await powerRes.json();
    const powerHits = Array.isArray(powerData) ? powerData : powerData.data;
    if (powerHits.find(p => p.uuid === sample.uuid)) {
      console.log('✅ Found baseline post via enginePower filter.');
    } else {
      console.error('❌ Baseline post missing from enginePower filter.');
    }
  }

  console.log('\n🎉 Verification Complete.');
}

main().catch(err => {
  console.error('\n❌ Fatal Error:', err);
  process.exit(1);
});