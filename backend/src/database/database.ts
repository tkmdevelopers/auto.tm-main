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
      return sequelize;
    },
  },
];
