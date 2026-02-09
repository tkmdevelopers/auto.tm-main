import { ApiProperty } from "@nestjs/swagger";
import {
  Table,
  Column,
  Model,
  HasMany,
  BelongsToMany,
  HasOne,
  DataType,
  ForeignKey,
  BelongsTo,
} from "sequelize-typescript";
import { Photo } from "src/photo/photo.entity";
import { Posts } from "src/post/post.entity";
import { Subscriptions } from "./subscription.entity";

@Table({ tableName: "subscription_order" })
export class SubscriptionOrder extends Model {
  @ApiProperty()
  @Column({
    primaryKey: true,
    type: DataType.UUID,
    defaultValue: DataType.UUIDV4,
  })
  uuid: string;
  @ApiProperty()
  @Column
  location: string;
  @ApiProperty()
  @Column
  phone: string;
  @Column
  status: string;
  @ForeignKey(() => Subscriptions)
  @Column({ type: DataType.UUID, allowNull: true })
  subscriptionId: string;
  @BelongsTo(() => Subscriptions)
  subscription: Subscriptions;
}
