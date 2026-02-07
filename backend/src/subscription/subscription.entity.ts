import { ApiProperty } from "@nestjs/swagger";
import {
  Table,
  Column,
  Model,
  HasMany,
  BelongsToMany,
  HasOne,
  DataType,
} from "sequelize-typescript";
import { Photo } from "src/photo/photo.entity";
import { Posts } from "src/post/post.entity";
import { SubscriptionOrder } from "./subscription_order.entity";

@Table({ tableName: "subscriptions" })
export class Subscriptions extends Model {
  @ApiProperty()
  @Column({ primaryKey: true, type: DataType.UUID, defaultValue: DataType.UUIDV4 })
  uuid: string;
  @ApiProperty()
  @Column({ type: DataType.JSONB, allowNull: false })
  name: Record<string, string>;
  @Column({ allowNull: true, unique: true })
  priority: number;
  @Column
  price: number;
  @ApiProperty()
  @HasOne(() => Photo, {
    foreignKey: "subscriptionId",
  })
  photo: Photo;

  @Column
  color: string;
  @Column({ type: DataType.JSONB, allowNull: false })
  description: Record<string, string>;
  @ApiProperty()
  @HasMany(() => Posts)
  posts: Posts[];
  @ApiProperty()
  @HasMany(() => SubscriptionOrder)
  order: SubscriptionOrder[];
}
