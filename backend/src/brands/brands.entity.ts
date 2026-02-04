import { ApiProperty } from "@nestjs/swagger";
import {
  Table,
  Column,
  Model,
  DataType,
  HasMany,
  BelongsToMany,
  HasOne,
} from "sequelize-typescript";
import { User } from "src/auth/auth.entity";
import { BrandsUser } from "src/junction/brands_user";
import { Models } from "src/models/models.entity";
import { Photo } from "src/photo/photo.entity";
import { Posts } from "src/post/post.entity";

@Table({ tableName: "brands" })
export class Brands extends Model {
  @ApiProperty()
  @Column({ primaryKey: true })
  uuid: string;
  @Column
  name: string;
  @HasMany(() => Models)
  models: Models[];
  @HasMany(() => Posts)
  posts: Posts[];
  @ApiProperty()
  @BelongsToMany(() => User, () => BrandsUser, "uuid")
  users: User[];
  @HasOne(() => Photo, {
    foreignKey: "brandsId",
  })
  photo: Photo;
  @Column({ allowNull: true })
  location: string;
}
