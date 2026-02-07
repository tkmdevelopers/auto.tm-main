import { Table, Column, Model, ForeignKey, DataType } from "sequelize-typescript";
import { Photo } from "src/photo/photo.entity";
import { Vlogs } from "src/vlog/vlog.entity";

// Distinct junction table for Vlog <-> Photo
@Table({
  tableName: "photo_vlogs",
  createdAt: false,
  updatedAt: false,
})
export class PhotoVlog extends Model {
  @Column({ primaryKey: true, autoIncrement: true })
  id: number;

  @ForeignKey(() => Vlogs)
  @Column({ type: DataType.UUID })
  vlogId: string;

  @ForeignKey(() => Photo)
  @Column({ type: DataType.UUID })
  photoUuid: string;
}
