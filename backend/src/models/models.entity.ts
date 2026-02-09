import { ApiProperty } from "@nestjs/swagger";
import {
  Table,
  Column,
  Model,
  DataType,
  HasMany,
  BelongsTo,
  ForeignKey,
  HasOne,
} from "sequelize-typescript";
import { Brands } from "src/brands/brands.entity";
import { Photo } from "src/photo/photo.entity";
import { Posts } from "src/post/post.entity";

@Table({ tableName: "models" })
export class Models extends Model {
  @ApiProperty()
  @Column({
    primaryKey: true,
    type: DataType.UUID,
    defaultValue: DataType.UUIDV4,
  })
  uuid: string;
  @ApiProperty()
  @Column
  name: string;
  @ForeignKey(() => Brands)
  @Column({ type: DataType.UUID, allowNull: true })
  brandId: string;

  // Optional year range for the model (used by seed data)
  @Column({ type: DataType.INTEGER, allowNull: true })
  yearstart: number | null;

  @Column({ type: DataType.INTEGER, allowNull: true })
  yearend: number | null;

  @HasOne(() => Photo, {
    foreignKey: "modelsId",
  })
  photo: Photo;
  @BelongsTo(() => Brands)
  brand: Brands;
  @HasMany(() => Posts)
  posts: Posts[];
}
