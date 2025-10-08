import { ApiProperty } from '@nestjs/swagger';
import {
  Table,
  Column,
  Model,
  BelongsToMany,
  BelongsTo,
  DataType,
} from 'sequelize-typescript';
import { User } from 'src/auth/auth.entity';
import { Banners } from 'src/banners/banners.entity';
import { Brands } from 'src/brands/brands.entity';
import { Categories } from 'src/categories/categories.entity';
import { PhotoPosts } from 'src/junction/photo_posts';
import { Models } from 'src/models/models.entity';
import { Posts } from 'src/post/post.entity';
import { Subscriptions } from 'src/subscription/subscription.entity';

@Table({ tableName: 'otp_temp' })
export class OtpTemp extends Model {
  @Column({ primaryKey: true })
  phone: string;
  @Column
  otp: string;
}
