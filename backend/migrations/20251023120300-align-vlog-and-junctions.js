'use strict';
/**
 * Alignment migration:
 * - Documents switch of entity tableName from 'vlog' to 'vlogs' (DB already uses 'vlogs').
 * - Junction entities renamed to photo_posts / photo_vlogs with columns photoUuid.
 * Since the new tables are created by earlier migrations, this is a no-op placeholder to keep history explicit.
 */
module.exports = { async up() {}, async down() {} };
