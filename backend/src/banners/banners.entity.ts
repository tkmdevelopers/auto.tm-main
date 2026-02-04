import { ApiProperty } from "@nestjs/swagger";
import {
  Table,
  Column,
  Model,
  HasOne,
  DataType,
  ForeignKey,
  BelongsTo,
} from "sequelize-typescript";
import { Photo } from "src/photo/photo.entity";
@Table({ tableName: "banners" })
export class Banners extends Model {
  @Column({ primaryKey: true })
  uuid: string;

  @Column({ type: DataType.JSONB, allowNull: false })
  creator: Record<string, string>;

  @ApiProperty()
  @HasOne(() => Photo, {
    foreignKey: "bannerId",
  })
  photo: Photo;
}
