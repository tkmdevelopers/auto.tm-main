import { ApiProperty } from "@nestjs/swagger";
import {
  Table,
  Column,
  Model,
  DataType,
  ForeignKey,
  BelongsTo,
  BelongsToMany,
} from "sequelize-typescript";
import { User } from "src/auth/auth.entity";
import { Brands } from "src/brands/brands.entity";
import { Categories } from "src/categories/categories.entity";
import { PhotoPosts } from "src/junction/photo_posts";
import { Models } from "src/models/models.entity";
import { Photo } from "src/photo/photo.entity";
import { Posts } from "src/post/post.entity";

@Table({ tableName: "comments" })
export class Comments extends Model {
  @ApiProperty()
  @Column({ primaryKey: true, type: DataType.UUID, defaultValue: DataType.UUIDV4 })
  uuid: string;
  @ApiProperty()
  @Column({ allowNull: false })
  message: string;
  @Column({ allowNull: true })
  status: boolean;
  @ForeignKey(() => User)
  @Column({ type: DataType.UUID, allowNull: true })
  userId: string;
  @BelongsTo(() => User)
  user: User;
  @ApiProperty()
  @Column
  sender: string;
  @ForeignKey(() => Posts)
  @Column({ type: DataType.UUID, allowNull: true })
  postId: string;
  @BelongsTo(() => Posts)
  post: Posts;

  // Self-referencing reply relationship
  @ForeignKey(() => Comments)
  @Column({ type: DataType.UUID, allowNull: true })
  replyTo: string;
  @BelongsTo(() => Comments, { foreignKey: "replyTo", as: "parent" })
  parent?: Comments;
}
