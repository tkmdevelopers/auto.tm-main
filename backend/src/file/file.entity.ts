import { ApiProperty } from "@nestjs/swagger";
import {
  BelongsTo,
  Column,
  DataType,
  ForeignKey,
  Model,
  Table,
} from "sequelize-typescript";
import { Posts } from "src/post/post.entity";

@Table({ tableName: "file" })
export class File extends Model {
  @Column({
    primaryKey: true,
    type: DataType.UUID,
    defaultValue: DataType.UUIDV4,
  })
  uuid: string;
  @Column({ type: DataType.STRING, allowNull: true })
  path: string | null;

  @ForeignKey(() => Posts)
  @Column({ type: DataType.UUID })
  postId: string;

  @BelongsTo(() => Posts)
  post: Posts;
}
