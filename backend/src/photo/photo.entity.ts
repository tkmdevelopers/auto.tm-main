import { ApiProperty } from '@nestjs/swagger';
import { DataTypes } from 'sequelize';
import {
  Table,
  Column,
  Model,
  HasMany,
  ForeignKey,
  PrimaryKey,
  BelongsToMany,
  BelongsTo,
  HasOne,
  DataType,
} from 'sequelize-typescript';
import { User } from 'src/auth/auth.entity';
import { Banners } from 'src/banners/banners.entity';
import { Brands } from 'src/brands/brands.entity';
import { Categories } from 'src/categories/categories.entity';
import { PhotoPosts } from 'src/junction/photo_posts';
import { PhotoVlog } from 'src/junction/photo_vlog';
import { Models } from 'src/models/models.entity';
import { Posts } from 'src/post/post.entity';
import { Subscriptions } from 'src/subscription/subscription.entity';
import { Vlogs } from 'src/vlog/vlog.entity';

@Table({ tableName: 'photo' })
export class Photo extends Model {
  map(arg0: (photo: any) => void): any {
    throw new Error('Method not implemented.');
  }
  @Column({ primaryKey: true })
  uuid: string;

  @Column({ type: DataType.JSON, allowNull: true })
  path: { small: string; medium: string; large: string } | null;
  @Column({allowNull:true})
  originalPath:string;

  // Aspect ratio metadata fields
  @ApiProperty({ description: 'Aspect ratio category (16:9, 4:3, 1:1, 9:16, 3:4, custom)', required: false })
  @Column({ type: DataType.STRING(20), allowNull: true })
  aspectRatio: string | null;

  @ApiProperty({ description: 'Original image width in pixels', required: false })
  @Column({ type: DataType.INTEGER, allowNull: true })
  width: number | null;

  @ApiProperty({ description: 'Original image height in pixels', required: false })
  @Column({ type: DataType.INTEGER, allowNull: true })
  height: number | null;

  @ApiProperty({ description: 'Decimal aspect ratio (width/height)', required: false })
  @Column({ type: DataType.FLOAT, allowNull: true })
  ratio: number | null;

  @ApiProperty({ description: 'Image orientation (landscape, portrait, square)', required: false })
  @Column({ type: DataType.STRING(20), allowNull: true })
  orientation: string | null;

  @ApiProperty()
  @BelongsTo(() => Banners, {
    foreignKey: 'bannerId',
  })
  banners: Banners;

  @ApiProperty()
  @BelongsTo(() => Categories, {
    foreignKey: 'categoryId',
  })
  categories: Categories;
  @ApiProperty()
  @BelongsTo(() => Subscriptions, {
    foreignKey: 'subscriptionId',
  })
  subscription: Subscriptions;
  @ApiProperty()
  @BelongsTo(() => Brands, {
    foreignKey: 'brandsId',
  })
  brand: Brands;
  @ApiProperty()
  @BelongsTo(() => Models, {
    foreignKey: 'modelsId',
  })
  model: Models;
  @ApiProperty()
  @BelongsTo(() => User, {
    foreignKey: 'userId',
  })
  user: User;
  @ApiProperty()
  @BelongsToMany(() => Posts, () => PhotoPosts, 'photoUuid')
  posts: Posts[];
}
