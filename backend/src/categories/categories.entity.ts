import { ApiProperty } from "@nestjs/swagger";
import {
  Table,
  Column,
  Model,
  HasMany,
  BelongsToMany,
  HasOne,
  DataType,
} from "sequelize-typescript";
import { Photo } from "src/photo/photo.entity";
import { Posts } from "src/post/post.entity";

@Table({ tableName: "categories" })
export class Categories extends Model {
  @ApiProperty()
  @Column({ primaryKey: true })
  uuid: string;
  @ApiProperty()
  @Column({ type: DataType.JSONB, allowNull: false })
  name: Record<string, string>;
  @Column({ type: DataType.JSONB, allowNull: false })
  creator: Record<string, string>;
  @Column({ allowNull: true, unique: true })
  priority: number;
  @ApiProperty()
  @HasOne(() => Photo, {
    foreignKey: "categoryId",
  })
  photo: Photo;
  @ApiProperty()
  @HasMany(() => Posts)
  posts: Posts[];
}
