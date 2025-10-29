import { ApiProperty } from '@nestjs/swagger';
import {
  Table,
  Column,
  Model,
  DataType,
  HasMany,
  BelongsTo,
  ForeignKey,
  HasOne,
} from 'sequelize-typescript';
import { Brands } from 'src/brands/brands.entity';
import { Photo } from 'src/photo/photo.entity';
import { Posts } from 'src/post/post.entity';

@Table({ tableName: 'models' })
export class Models extends Model {
  @ApiProperty()
  @Column({ primaryKey: true })
  uuid: string;
  @ApiProperty()
  @Column
  name: string;
  @ApiProperty()
  @Column({ type: DataType.INTEGER, allowNull: true })
  yearstart: number;
  @ApiProperty()
  @Column({ type: DataType.INTEGER, allowNull: true })
  yearend: number;
  @ForeignKey(() => Brands)
  @Column({ type: DataType.STRING, allowNull: true })
  brandId: string;
  @HasOne(() => Photo, {
      foreignKey: 'modelsId',
    })
    photo: Photo;
  @BelongsTo(() => Brands)
  brand: Brands;
  @HasMany(() => Posts)
  posts: Posts[];
}
