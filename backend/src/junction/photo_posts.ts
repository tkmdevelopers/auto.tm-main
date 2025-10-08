import { Table, Column, Model, ForeignKey } from 'sequelize-typescript';
import { Photo } from 'src/photo/photo.entity';
import { Posts } from 'src/post/post.entity';

@Table({
  tableName: 'photo_products',
  createdAt: false,
  updatedAt: false, // This is a common naming convention
})
export class PhotoPosts extends Model {
  @Column({ primaryKey: true, autoIncrement: true })
  id: number;

  @ForeignKey(() => Posts)
  postId: string;

  @ForeignKey(() => Photo)
  uuid: string;
}
