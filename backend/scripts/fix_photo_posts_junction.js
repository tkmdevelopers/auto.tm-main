/**
 * Fix PhotoPosts junction table - rename 'uuid' column to 'photoUuid'
 * 
 * The junction table was using 'uuid' instead of 'photoUuid' causing
 * photos not to load for posts.
 * 
 * Run with: node scripts/fix_photo_posts_junction.js
 */

const { Sequelize } = require('sequelize');
require('dotenv').config();

const sequelize = new Sequelize(
  process.env.DATABASE,
  process.env.DATABASE_USERNAME,
  process.env.DATABASE_PASSWORD,
  {
    host: process.env.DATABASE_HOST,
    port: process.env.DATABASE_PORT || 5432,
    dialect: 'postgres',
    logging: console.log,
  }
);

async function fixPhotoPostsJunction() {
  try {
    console.log('🔗 Connecting to database...');
    await sequelize.authenticate();
    console.log('✅ Database connection established\n');

    // Check if 'uuid' column exists (old incorrect column)
    console.log('📋 Checking table structure...');
    const [columns] = await sequelize.query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'photo_posts'
    `);
    
    const columnNames = columns.map(c => c.column_name);
    console.log('Current columns:', columnNames);

    const hasUuid = columnNames.includes('uuid');
    const hasPhotoUuid = columnNames.includes('photoUuid');

    if (hasUuid && !hasPhotoUuid) {
      console.log('\n🔧 Renaming column "uuid" to "photoUuid"...');
      await sequelize.query(`
        ALTER TABLE photo_posts 
        RENAME COLUMN uuid TO "photoUuid"
      `);
      console.log('✅ Column renamed successfully!');
    } else if (hasPhotoUuid) {
      console.log('\n✅ Column "photoUuid" already exists - no changes needed');
    } else if (hasUuid && hasPhotoUuid) {
      console.log('\n⚠️  Both "uuid" and "photoUuid" exist!');
      console.log('Please manually review the table structure.');
    } else {
      console.log('\n❌ Neither column found - something is wrong!');
    }

    // Show some sample data
    console.log('\n📊 Sample junction records:');
    const [records] = await sequelize.query(`
      SELECT * FROM photo_posts LIMIT 5
    `);
    console.table(records);

    // Count records
    const [countResult] = await sequelize.query(`
      SELECT COUNT(*) as total FROM photo_posts
    `);
    console.log(`\n📈 Total junction records: ${countResult[0].total}`);

  } catch (error) {
    console.error('❌ Migration failed:', error);
    process.exit(1);
  } finally {
    await sequelize.close();
    console.log('\n🔌 Database connection closed');
  }
}

fixPhotoPostsJunction()
  .then(() => {
    console.log('\n✨ Migration completed successfully!');
    console.log('\n⚠️  IMPORTANT: Restart your backend server for changes to take effect');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n💥 Migration failed:', error);
    process.exit(1);
  });
