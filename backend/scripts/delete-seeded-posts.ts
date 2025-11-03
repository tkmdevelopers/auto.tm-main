/*
 * Delete posts & photos created by the seeding script.
 * Usage (Windows cmd):
 *   npx ts-node ./scripts/delete-seeded-posts.ts
 *
 * Currently relies on heuristic: delete posts newer than a given date range OR all if passed --all.
 * Improve by adding explicit seedBatch column if needed.
 */
import { Sequelize } from 'sequelize-typescript';
import { config } from 'dotenv';
import { Posts } from '../src/post/post.entity';
import { Photo } from '../src/photo/photo.entity';

config();

const sequelize = new Sequelize({
  dialect: 'postgres',
  host: process.env.DB_HOST || 'localhost',
  port: +(process.env.DB_PORT || 5432),
  database: process.env.DB_NAME || 'auto_tm',
  username: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASS || 'postgres',
  logging: false,
  models: [Posts, Photo],
});

async function main() {
  if (process.env.NODE_ENV === 'production') {
    console.error('Refusing to delete in production environment.');
    process.exit(1);
  }
  await sequelize.authenticate();
  const all = process.argv.includes('--all');

  if (all) {
    console.log('Deleting ALL posts and photos (careful)...');
    await Photo.destroy({ where: {} });
    await Posts.destroy({ where: {} });
  } else {
    // Placeholder heuristic (adjust to your schema e.g. createdAt filter)
    const cutoff = new Date(Date.now() - 1000 * 60 * 60 * 24); // last 24h
    console.log('Deleting posts created in last 24h (heuristic).');
    // If createdAt field exists on Posts:
    try {
      // @ts-ignore dynamic attribute
      const posts = await Posts.findAll({ where: { createdAt: { $gte: cutoff } } });
      const postIds = posts.map(p => p.uuid);
      if (postIds.length) {
        await Photo.destroy({ where: { postsId: postIds } as any });
        await Posts.destroy({ where: { uuid: postIds } });
        console.log(`Deleted ${postIds.length} posts.`);
      } else {
        console.log('No recent posts found.');
      }
    } catch (e) {
      console.warn('Heuristic deletion failed; consider implementing explicit seedBatch tagging.', e);
    }
  }
  await sequelize.close();
}

main().catch(err => {
  console.error('Delete script failed:', err);
  process.exit(1);
});
