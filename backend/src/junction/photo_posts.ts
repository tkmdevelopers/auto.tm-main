import {
  Table,
  Column,
  Model,
  ForeignKey,
  DataType,
} from "sequelize-typescript";
import { Photo } from "src/photo/photo.entity";
import { Posts } from "src/post/post.entity";

// Distinct junction table for Post <-> Photo
@Table({
  tableName: "photo_posts",
  createdAt: false,
  updatedAt: false,
})
export class PhotoPosts extends Model {
  @Column({ primaryKey: true, autoIncrement: true })
  id: number;

  @ForeignKey(() => Posts)
  @Column({ type: DataType.UUID })
  postId: string;

  @ForeignKey(() => Photo)
  @Column({ type: DataType.UUID })
  photoUuid: string;
}
