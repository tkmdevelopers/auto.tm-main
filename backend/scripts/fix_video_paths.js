#!/usr/bin/env node
/**
 * One-off utility to normalize existing Video.url values to relative paths and (optionally)
 * print the would-be publicUrl. Safe to run multiple times (idempotent if already relative).
 *
 * Usage:
 *   node backend/scripts/fix_video_paths.js
 */
const { Sequelize } = require('sequelize');
const path = require('path');
const fs = require('fs');
require('dotenv').config({ path: path.join(process.cwd(), '.env') });

// Simple CLI arg parser: --db-name= --db-user= --db-pass= --db-host= --db-port=
const argMap = process.argv.slice(2).reduce((acc, cur) => {
  const [k, v] = cur.split('=');
  if (k && v) acc[k.replace(/^--/, '')] = v; return acc;
}, {});

// Try config.json if present
let configJson;
try {
  const raw = fs.readFileSync(path.join(process.cwd(), 'backend', 'config', 'config.json'), 'utf8');
  configJson = JSON.parse(raw).development || {};
} catch (e) {
  // ignore if not found
}

// Adjust connection details as per your environment variables or config.
const dbName = argMap['db-name'] || process.env.DB_NAME || configJson?.database || 'postgres';
const dbUser = argMap['db-user'] || process.env.DB_USER || configJson?.username || 'postgres';
const dbPass = argMap['db-pass'] || process.env.DB_PASS || configJson?.password || 'postgres';
const dbHost = argMap['db-host'] || process.env.DB_HOST || configJson?.host || '127.0.0.1';
const dbPort = +(argMap['db-port'] || process.env.DB_PORT || 5432);

console.log(`[fix_video_paths] Using connection ${dbUser}@${dbHost}:${dbPort}/${dbName}`);
const sequelize = new Sequelize(dbName, dbUser, dbPass, {
  host: dbHost,
  port: dbPort,
  dialect: 'postgres',
  logging: false,
});

(async () => {
  try {
    // Minimal model definition to update URLs
    const Video = sequelize.define('video', {
      id: { type: require('sequelize').INTEGER, primaryKey: true, autoIncrement: true },
      url: { type: require('sequelize').STRING },
    }, { tableName: 'video', timestamps: true });

    await sequelize.authenticate();
    console.log('[fix_video_paths] Connected to DB');

    const videos = await Video.findAll();
    console.log(`[fix_video_paths] Found ${videos.length} video rows`);

    for (const v of videos) {
      const current = v.get('url');
      if (!current) continue;
      const uploadsIndex = current.lastIndexOf('uploads');
      let relative = current;
      if (uploadsIndex !== -1) {
        relative = current.substring(uploadsIndex + 'uploads'.length).replace(/^[\\/]+/, '');
      }
      // If already relative (no path separators that look like absolute drive roots), skip update
      if (relative === current) {
        console.log(`- video ${v.get('id')} already relative: ${relative}`);
        continue;
      }
      await v.update({ url: relative });
      console.log(`✔ Normalized video ${v.get('id')} -> ${relative} (publicUrl: /media/${relative})`);
    }

    console.log('[fix_video_paths] Done');
    process.exit(0);
  } catch (err) {
    console.error('[fix_video_paths] Error:', err.message);
    process.exit(1);
  }
})();
