import { Table, Column, Model, ForeignKey, DataType } from "sequelize-typescript";
import { User } from "src/auth/auth.entity";
import { Brands } from "src/brands/brands.entity";
import { Photo } from "src/photo/photo.entity";
import { Posts } from "src/post/post.entity";

@Table({
  tableName: "brands_user",
  createdAt: false,
  updatedAt: false, // This is a common naming convention
})
export class BrandsUser extends Model {
  @Column({ primaryKey: true, autoIncrement: true })
  id: number;

  @ForeignKey(() => User)
  @Column({ type: DataType.UUID })
  userId: string;

  // Rename FK to brandId for clarity; matches migration field name
  @ForeignKey(() => Brands)
  @Column({ type: DataType.UUID })
  brandId: string;
}
