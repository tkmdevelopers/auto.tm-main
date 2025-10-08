import { ApiProperty } from '@nestjs/swagger';
import {
  Table,
  Column,
  Model,
  DataType,
  ForeignKey,
  BelongsTo,
  Default,
  BelongsToMany,
} from 'sequelize-typescript';
import { User } from 'src/auth/auth.entity';
import { PhotoVlog } from 'src/junction/photo_vlog';
import { Photo } from 'src/photo/photo.entity';

@Table({ tableName: 'vlog' })
export class Vlogs extends Model {
  @ApiProperty()
  @Column({
    primaryKey: true,
  })
  uuid: string;

  @ApiProperty()
  @Column({
    type: DataType.STRING,
    allowNull: false,
  })
  title: string;
  @ApiProperty()
  @Column({
    type: DataType.STRING,
    allowNull: true,
  })
  description: string;

  @ApiProperty()
  @Column({
    type: DataType.STRING,
    allowNull: true,
  })
  tag: string;

  @ApiProperty()
  @Column({
    type: DataType.STRING,
    allowNull: true,
  })
  videoUrl: string;

  @ApiProperty()
  @Default(false)
  @Column({
    type: DataType.BOOLEAN,
    allowNull: false,
  })
  isActive: boolean;

  @ApiProperty()
  @Column({
    type: DataType.JSON,
    allowNull: true,
  })
  thumbnail: object;

  @ApiProperty()
  @ForeignKey(() => User)
  @Column({
    allowNull: true,
  })
  userId: string;

  @BelongsTo(() => User)
  user: User;

  @ApiProperty({ enum: ['Pending', 'Accepted', 'Declined'] })
  @Default('Pending')
  @Column({
    type: DataType.ENUM('Pending', 'Accepted', 'Declined'),
    allowNull: false,
  })
  status: 'Pending' | 'Accepted' | 'Declined';

  @ApiProperty()
  @Column({
    type: DataType.STRING,
    allowNull: true,
  })
  declineMessage: string;
}
