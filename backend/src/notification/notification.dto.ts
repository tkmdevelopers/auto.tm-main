import { ApiProperty } from "@nestjs/swagger";
import { NotificationType, NotificationStatus } from "./notification.entity";

export class notification {
  @ApiProperty()
  message: string;
}

export class orderMessage {
  @ApiProperty()
  phone: string;
}

export class notificationsFirebase {
  @ApiProperty()
  token: string;
  @ApiProperty()
  title: string;
  @ApiProperty()
  body: string;
}

export class notificationsFirebaseWithoutToken {
  @ApiProperty()
  title: string;
  @ApiProperty()
  body: string;
}

export class notificationFirebaseToSubscribe {
  @ApiProperty()
  title: string;
  @ApiProperty()
  body: string;
  @ApiProperty()
  uuid: string;
}

// New DTOs for notification history and admin panel
export class CreateNotificationDto {
  @ApiProperty()
  title: string;

  @ApiProperty()
  body: string;

  @ApiProperty({ enum: NotificationType })
  type: NotificationType;

  @ApiProperty({ required: false, type: Object })
  targetData?: Record<string, any>;

  @ApiProperty({ required: false, type: Object })
  additionalData?: Record<string, any>;

  @ApiProperty({ required: false })
  topic?: string;

  @ApiProperty({ required: false })
  scheduledFor?: Date;

  @ApiProperty({ required: false, default: false })
  isScheduled?: boolean;
}

export class UpdateNotificationDto {
  @ApiProperty({ required: false })
  title?: string;

  @ApiProperty({ required: false })
  body?: string;

  @ApiProperty({ required: false, enum: NotificationType })
  type?: NotificationType;

  @ApiProperty({ required: false, type: Object })
  targetData?: Record<string, any>;

  @ApiProperty({ required: false, type: Object })
  additionalData?: Record<string, any>;

  @ApiProperty({ required: false })
  topic?: string;

  @ApiProperty({ required: false })
  scheduledFor?: Date;

  @ApiProperty({ required: false })
  isScheduled?: boolean;
}

export class NotificationHistoryResponse {
  @ApiProperty()
  uuid: string;

  @ApiProperty()
  title: string;

  @ApiProperty()
  body: string;

  @ApiProperty({ enum: NotificationType })
  type: NotificationType;

  @ApiProperty({ enum: NotificationStatus })
  status: NotificationStatus;

  @ApiProperty()
  totalRecipients: number;

  @ApiProperty()
  successfulDeliveries: number;

  @ApiProperty()
  failedDeliveries: number;

  @ApiProperty()
  sentBy: string;

  @ApiProperty()
  createdAt: Date;

  @ApiProperty()
  updatedAt: Date;
}

export class FindAllNotificationsDto {
  @ApiProperty({ required: false, enum: NotificationType })
  type?: NotificationType;

  @ApiProperty({ required: false, enum: NotificationStatus })
  status?: NotificationStatus;

  @ApiProperty({ required: false })
  search?: string;

  @ApiProperty({ required: false })
  sortBy?: string;

  @ApiProperty({ required: false, enum: ["ASC", "DESC"] })
  sortOrder?: "ASC" | "DESC";

  @ApiProperty({ required: false, type: Number })
  page?: number;

  @ApiProperty({ required: false, type: Number })
  limit?: number;

  @ApiProperty({ required: false })
  startDate?: string;

  @ApiProperty({ required: false })
  endDate?: string;
}

export class NotificationParamDto {
  @ApiProperty()
  uuid: string;
}

export class SendNotificationDto {
  @ApiProperty()
  title: string;

  @ApiProperty()
  body: string;

  @ApiProperty({ enum: NotificationType })
  type: NotificationType;

  @ApiProperty({ required: false, type: Object })
  targetData?: Record<string, any>;

  @ApiProperty({ required: false, type: Object })
  additionalData?: Record<string, any>;

  @ApiProperty({ required: false })
  topic?: string;

  @ApiProperty({ required: false })
  scheduledFor?: Date;
}

export class NotificationStatsDto {
  @ApiProperty()
  totalNotifications: number;

  @ApiProperty()
  totalRecipients: number;

  @ApiProperty()
  totalSuccessfulDeliveries: number;

  @ApiProperty()
  totalFailedDeliveries: number;

  @ApiProperty()
  successRate: number;

  @ApiProperty({ type: [Object] })
  notificationsByType: Record<string, number>;

  @ApiProperty({ type: [Object] })
  notificationsByStatus: Record<string, number>;
}
