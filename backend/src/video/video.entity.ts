import {
  BelongsTo,
  Column,
  DataType,
  ForeignKey,
  Model,
  Table,
} from "sequelize-typescript";
import { Posts } from "src/post/post.entity";

@Table({ tableName: "video" })
export class Video extends Model {
  @Column({ type: DataType.STRING })
  url: string;

  @ForeignKey(() => Posts)
  @Column({ type: DataType.UUID })
  postId: string;

  @BelongsTo(() => Posts)
  post: Posts;
}
