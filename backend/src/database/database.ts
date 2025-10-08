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

5432;

export const databaseProviders = [
  {
    provide: 'SEQUELIZE',
    useFactory: async () => {
      const sequelize = new Sequelize({
        dialect: 'postgres',
        host: 'localhost',
        port: 5432,
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
      await sequelize.sync({ alter: true });
      return sequelize;
    },
  },
];
