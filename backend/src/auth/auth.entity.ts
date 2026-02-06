import { ApiProperty } from "@nestjs/swagger";
import { DataTypes } from "sequelize";
import {
  Table,
  Column,
  Model,
  IsEmail,
  HasMany,
  Length,
  DataType,
  AllowNull,
  HasOne,
  BelongsToMany,
} from "sequelize-typescript";
import { Brands } from "src/brands/brands.entity";
import { Comments } from "src/comments/comments.entity";
import { BrandsUser } from "src/junction/brands_user";
import { Photo } from "src/photo/photo.entity";
import { Posts } from "src/post/post.entity";
import { Vlogs } from "src/vlog/vlog.entity";
enum UserRole {
  ADMIN = "admin",
  OWNER = "owner",
  USER = "user",
}
@Table({ tableName: "users" })
export class User extends Model {
  @ApiProperty()
  @Column({ primaryKey: true })
  uuid: string;
  @ApiProperty()
  @Column({ allowNull: true })
  name: string;
  @ApiProperty({
    example: "99362120020",
  })
  @ApiProperty()
  @Column({ allowNull: true, unique: true })
  email: string;
  @ApiProperty()
  @Column({ allowNull: true })
  password: string;
  @ApiProperty()
  @Column({
    type: DataType.STRING(20),
    allowNull: true,
    unique: true,
  })
  phone: string;

  @ApiProperty()
  @Column({ defaultValue: false })
  status: boolean;
  @ApiProperty()
  @Column({
    type: DataType.ENUM(...Object.values(UserRole)),
    allowNull: false,
    defaultValue: UserRole?.USER,
  })
  role: UserRole;
  // Stores bcrypt hash of the current valid refresh token (never store plaintext)
  @Column({ type: DataType.TEXT, allowNull: true })
  refreshTokenHash: string;
  @Column({ allowNull: true })
  location: string;
  @HasMany(() => Posts)
  posts: Posts[];
  @HasMany(() => Comments)
  comments: Comments[];
  @Column({ type: DataType.ARRAY(DataType.STRING), allowNull: true })
  access: string[];
  @ApiProperty()
  @HasOne(() => Photo, {
    foreignKey: "userId",
  })
  avatar: Photo;
  @HasMany(() => Vlogs, {
    foreignKey: "userId",
  })
  vlogs: Vlogs[];

  @ApiProperty()
  @Column({ allowNull: true })
  firebaseToken: string;
  @BelongsToMany(() => Brands, () => BrandsUser, "userId")
  brands: Brands[];
}
