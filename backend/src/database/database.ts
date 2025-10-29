import { Sequelize } from 'sequelize-typescript';
import { User } from 'src/auth/auth.entity';
import 'dotenv/config';
import { Models } from 'src/models/models.entity';
import { Convert, Posts } from 'src/post/post.entity';
import { Brands } from 'src/brands/brands.entity';
import { Photo } from 'src/photo/photo.entity';
import { PhotoPosts } from 'src/junction/photo_posts';
import { Banners } from 'src/banners/banners.entity';
import { Categories } from 'src/categories/categories.entity';
import { Comments } from 'src/comments/comments.entity';
import { Subscriptions } from 'src/subscription/subscription.entity';
import { SubscriptionOrder } from 'src/subscription/subscription_order.entity';
import { Vlogs } from 'src/vlog/vlog.entity';
import { Video } from 'src/video/video.entity';
import { BrandsUser } from 'src/junction/brands_user';
import { OtpTemp } from 'src/otp/otp.entity';
import { File } from 'src/file/file.entity';
import { NotificationHistory } from 'src/notification/notification.entity';

// Removed stray numeric literal and use environment-driven host/port.

export const databaseProviders = [
  {
    provide: 'SEQUELIZE',
    useFactory: async () => {
  const host = process.env.DATABASE_HOST || 'db';
  const port = Number(process.env.DATABASE_PORT) || 5432;
  // Debug log of resolved host/credentials (remove in production)
  // eslint-disable-next-line no-console
  console.log('[database] Connecting to', { host, port, user: process.env.DATABASE_USERNAME, db: process.env.DATABASE });

      const sequelize = new Sequelize({
        dialect: 'postgres',
        host,
        port,
        username: process.env.DATABASE_USERNAME,
        password: process.env.DATABASE_PASSWORD,
        database: process.env.DATABASE,
        logging: false,
      });
      sequelize.addModels([
        User,
        Models,
        Brands,
        Posts,
        Photo,
        PhotoPosts,
        BrandsUser,
        Banners,
        Categories,
        Comments,
        Subscriptions,
        SubscriptionOrder,
        Vlogs,
        Video,
        OtpTemp,
        Convert,
        File,
        NotificationHistory,
      ]);
      // Simple retry for initial sync in containerized startup (DB may be ready but auth pending)
      // Optional: Remove alter syncing; rely on migrations only.
      try {
        await sequelize.authenticate();
        // eslint-disable-next-line no-console
        console.log('[database] Connection authenticated successfully');
      } catch (err) {
        // eslint-disable-next-line no-console
        console.error('[database] Initial authentication failed:', err.message);
        throw err;
      }

      // --- Optional dev-only auto sync (Option B) ---
      // Enable with DB_AUTO_SYNC=true in .env (DO NOT use in production).
      // Additional knobs:
      //   DB_SYNC_ALTER=true   -> uses { alter: true } to try to match columns (risk of unintended changes)
      //   DB_SYNC_FORCE=true   -> uses { force: true } (DROPS tables; never use with real data)
      //   DB_SYNC_LOG=true     -> verbose logging
      //   DB_SYNC_FAIL_EXIT=true -> process.exit(1) if sync fails
      const autoSync = (process.env.DB_AUTO_SYNC || '').toLowerCase() === 'true';
      if (autoSync) {
        const useAlter = (process.env.DB_SYNC_ALTER || '').toLowerCase() === 'true';
        const useForce = (process.env.DB_SYNC_FORCE || '').toLowerCase() === 'true';
        const verbose = (process.env.DB_SYNC_LOG || '').toLowerCase() === 'true';
        const failExit = (process.env.DB_SYNC_FAIL_EXIT || '').toLowerCase() === 'true';
        if (useForce && useAlter) {
          // eslint-disable-next-line no-console
          console.warn('[database] Both DB_SYNC_FORCE and DB_SYNC_ALTER set. Using FORCE only.');
        }
        // Safety: warn loudly if force enabled
        if (useForce) {
          // eslint-disable-next-line no-console
          console.warn('[database] WARNING: DB_SYNC_FORCE=true -> All tables will be DROPPED and recreated.');
        }
        // Build sync options
        const syncOptions: any = {};
        if (useForce) syncOptions.force = true; else if (useAlter) syncOptions.alter = true;
        try {
          // eslint-disable-next-line no-console
          console.log('[database] Auto sync enabled. Options:', syncOptions);
          const started = Date.now();
          await sequelize.sync(syncOptions);
          const ms = Date.now() - started;
          // eslint-disable-next-line no-console
          console.log(`[database] Auto sync completed in ${ms}ms`);
        } catch (syncErr: any) {
          // eslint-disable-next-line no-console
          console.error('[database] Auto sync failed:', syncErr.message);
          if (verbose) {
            // eslint-disable-next-line no-console
            console.error(syncErr);
          }
          if (failExit) {
            // eslint-disable-next-line no-console
            console.error('[database] Exiting due to DB_SYNC_FAIL_EXIT=true');
            process.exit(1);
          }
        }
      }
      return sequelize;
    },
  },
];
