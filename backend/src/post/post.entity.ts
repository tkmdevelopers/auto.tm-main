import { ApiProperty } from '@nestjs/swagger';
import { DataTypes, IntegerDataType } from 'sequelize';
import {
  Table,
  Column,
  Model,
  DataType,
  ForeignKey,
  BelongsTo,
  BelongsToMany,
  HasMany,
  HasOne,
} from 'sequelize-typescript';
import { User } from 'src/auth/auth.entity';
import { Brands } from 'src/brands/brands.entity';
import { Categories } from 'src/categories/categories.entity';
import { Comments } from 'src/comments/comments.entity';
import { File } from 'src/file/file.entity';
import { PhotoPosts } from 'src/junction/photo_posts';
import { Models } from 'src/models/models.entity';
import { Photo } from 'src/photo/photo.entity';
import { Subscriptions } from 'src/subscription/subscription.entity';
import { Video } from 'src/video/video.entity';
enum UserRole {
  ADMIN = 'admin',
  OWNER = 'owner',
  USER = 'user',
}
@Table({ tableName: 'posts' })
export class Posts extends Model {
  @ApiProperty()
  @Column({ primaryKey: true })
  uuid: string;
  @ForeignKey(() => Brands)
  @Column({ type: DataType.STRING, allowNull: true })
  brandsId: string;
  @BelongsTo(() => Brands)
  brand: Brands;
  @ForeignKey(() => Models)
  @Column({ type: DataType.STRING, allowNull: true })
  modelsId: string;
  @BelongsTo(() => Models)
  model: Models;
  @Column
  condition: string;
  @Column
  transmission: string;
  @Column
  engineType: string;
  @Column({ type: DataType.DOUBLE, allowNull: true })
  enginePower: number;
  @Column
  year: number;
  @Column({ type: DataType.DOUBLE, allowNull: true })
  milleage: number;
  @Column
  vin: string;
  @Column({type: DataType.DOUBLE, allowNull: true })
  originalPrice: number;
  @Column({type: DataType.DOUBLE, allowNull: true })
  price: number;
  @Column
  originalCurrency: string;
  @Column
  currency: string;
  @Column({ type: DataType.JSON, allowNull: true })
  personalInfo: { name: string; location: string; phone: string } | null;
  @Column
  description: string;
  @Column({ allowNull: true })
  location: string;
  @ForeignKey(() => User)
  @Column({ type: DataType.STRING, allowNull: true })
  userId: string;
  @BelongsTo(() => User)
  user: User;
  @Column({ allowNull: true })
  status: boolean;
  @Column({ allowNull: true, defaultValue: 'false' })
  credit: boolean;
  @Column({ allowNull: true, defaultValue: 'true' })
  exchange: boolean;
  @ForeignKey(() => Categories)
  @Column({ type: DataType.STRING, allowNull: true })
  categoryId: string;
  @BelongsTo(() => Categories)
  category: Categories;
  @ForeignKey(() => Subscriptions)
  @Column({ type: DataType.STRING, allowNull: true })
  subscriptionId: string;
  @BelongsTo(() => Subscriptions)
  subscription: Subscriptions;
  @HasMany(() => Comments)
  comments: Comments[];
  @ApiProperty()
  @BelongsToMany(() => Photo, () => PhotoPosts, 'postId')
  photo: Photo[];
  @HasOne(() => Video)
  video: Video;
  @HasOne(() => File)
  file: File;
}
@Table({ tableName: 'convert_prices', createdAt: false, updatedAt: false })
export class Convert extends Model {
  @Column({})
  label: string;
  @Column({ type: 'decimal' })
  rate: number;
}
