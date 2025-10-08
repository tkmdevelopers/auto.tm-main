import { Table, Column, Model, ForeignKey } from 'sequelize-typescript';
import { Photo } from 'src/photo/photo.entity';
import { Vlogs } from 'src/vlog/vlog.entity';

@Table({
  tableName: 'photo_products',
  createdAt: false,
  updatedAt: false, // This is a common naming convention
})
export class PhotoVlog extends Model {
  @Column({ primaryKey: true, autoIncrement: true })
  id: number;

  @ForeignKey(() => Vlogs)
  vlogId: string;

  @ForeignKey(() => Photo)
  uuid: string;
}
