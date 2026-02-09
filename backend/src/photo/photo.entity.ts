import { ApiProperty } from "@nestjs/swagger";
import { DataTypes } from "sequelize";
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
} from "sequelize-typescript";
import { User } from "src/auth/auth.entity";
import { Banners } from "src/banners/banners.entity";
import { Brands } from "src/brands/brands.entity";
import { Categories } from "src/categories/categories.entity";
import { PhotoPosts } from "src/junction/photo_posts";
import { PhotoVlog } from "src/junction/photo_vlog";
import { Models } from "src/models/models.entity";
import { Posts } from "src/post/post.entity";
import { Subscriptions } from "src/subscription/subscription.entity";
import { Vlogs } from "src/vlog/vlog.entity";

@Table({ tableName: "photo" })
export class Photo extends Model {
  map(arg0: (photo: any) => void): any {
    throw new Error("Method not implemented.");
  }
  @Column({
    primaryKey: true,
    type: DataType.UUID,
    defaultValue: DataType.UUIDV4,
  })
  uuid: string;

  @Column({ type: DataType.JSON, allowNull: true })
  path: { small: string; medium: string; large: string } | null;
  @Column({ allowNull: true })
  originalPath: string;
  @ApiProperty()
  @BelongsTo(() => Banners, {
    foreignKey: "bannerId",
  })
  banners: Banners;

  @ApiProperty()
  @BelongsTo(() => Categories, {
    foreignKey: "categoryId",
  })
  categories: Categories;
  @ApiProperty()
  @BelongsTo(() => Subscriptions, {
    foreignKey: "subscriptionId",
  })
  subscription: Subscriptions;
  @ApiProperty()
  @BelongsTo(() => Brands, {
    foreignKey: "brandsId",
  })
  brand: Brands;
  @ApiProperty()
  @BelongsTo(() => Models, {
    foreignKey: "modelsId",
  })
  model: Models;
  @ApiProperty()
  @BelongsTo(() => User, {
    foreignKey: "userId",
  })
  user: User;
  @ApiProperty()
  @BelongsToMany(() => Posts, () => PhotoPosts, "photoUuid")
  posts: Posts[];
}
