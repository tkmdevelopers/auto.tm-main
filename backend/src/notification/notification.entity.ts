import { ApiProperty } from '@nestjs/swagger';
import {
  Table,
  Column,
  Model,
  DataType,
  ForeignKey,
  BelongsTo,
  Default,
} from 'sequelize-typescript';
import { User } from 'src/auth/auth.entity';

export enum NotificationType {
  ALL_USERS = 'all_users',
  BRAND_SUBSCRIBERS = 'brand_subscribers',
  SPECIFIC_USER = 'specific_user',
  TOPIC = 'topic',
}

export enum NotificationStatus {
  PENDING = 'pending',
  SENT = 'sent',
  FAILED = 'failed',
  PARTIAL = 'partial',
}

@Table({ tableName: 'notification_history' })
export class NotificationHistory extends Model {
  @ApiProperty()
  @Column({
    primaryKey: true,
    type: DataType.UUID,
    defaultValue: DataType.UUIDV4,
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
    type: DataType.TEXT,
    allowNull: false,
  })
  body: string;

  @ApiProperty({ enum: NotificationType })
  @Column({
    type: DataType.ENUM(...Object.values(NotificationType)),
    allowNull: false,
  })
  type: NotificationType;

  @ApiProperty({ enum: NotificationStatus })
  @Default(NotificationStatus.PENDING)
  @Column({
    type: DataType.ENUM(...Object.values(NotificationStatus)),
    allowNull: false,
  })
  status: NotificationStatus;

  @ApiProperty()
  @Column({
    type: DataType.JSON,
    allowNull: true,
  })
  targetData: object; // Store target information (user IDs, brand IDs, etc.)

  @ApiProperty()
  @Column({
    type: DataType.INTEGER,
    defaultValue: 0,
  })
  totalRecipients: number;

  @ApiProperty()
  @Column({
    type: DataType.INTEGER,
    defaultValue: 0,
  })
  successfulDeliveries: number;

  @ApiProperty()
  @Column({
    type: DataType.INTEGER,
    defaultValue: 0,
  })
  failedDeliveries: number;

  @ApiProperty()
  @Column({
    type: DataType.JSON,
    allowNull: true,
  })
  deliveryDetails: object; // Store detailed delivery results

  @ApiProperty()
  @Column({
    type: DataType.JSON,
    allowNull: true,
  })
  additionalData: object; // Store any additional data (images, actions, etc.)

  @ForeignKey(() => User)
  @Column
  sentBy: string; // Admin who sent the notification

  @BelongsTo(() => User)
  sender: User;

  @ApiProperty()
  @Column({
    type: DataType.DATE,
    allowNull: true,
  })
  scheduledFor: Date; // For scheduled notifications

  @ApiProperty()
  @Column({
    type: DataType.BOOLEAN,
    defaultValue: false,
  })
  isScheduled: boolean;

  @ApiProperty()
  @Column({
    type: DataType.STRING,
    allowNull: true,
  })
  topic: string; // For topic-based notifications

  @ApiProperty()
  @Column({
    type: DataType.TEXT,
    allowNull: true,
  })
  errorMessage: string; // Store error messages if any
}
