import {
  Body,
  Controller,
  Post,
  Get,
  Put,
  Patch,
  Delete,
  Param,
  Query,
  Req,
  UseGuards,
  ParseUUIDPipe,
} from "@nestjs/common";
import {
  ApiTags,
  ApiSecurity,
  ApiOperation,
  ApiResponse,
  ApiParam,
  ApiQuery,
} from "@nestjs/swagger";
import { NotificationService } from "./notification.service";
import {
  notificationFirebaseToSubscribe,
  notificationsFirebase,
  notificationsFirebaseWithoutToken,
  CreateNotificationDto,
  UpdateNotificationDto,
  FindAllNotificationsDto,
  SendNotificationDto,
  NotificationHistoryResponse,
  NotificationStatsDto,
} from "./notification.dto";
import { AuthGuard } from "src/guards/auth.guard";
import { AdminGuard } from "src/guards/admin.guard";
import { Request } from "express";

@Controller({
  path: "notifications",
  version: "1",
})
@ApiTags("Notifications")
export class NotificationsController {
  constructor(private readonly firebaseService: NotificationService) {}

  // Legacy endpoints (existing functionality)
  @Post("send-to-all")
  @ApiOperation({ summary: "Send notification to all users (Legacy)" })
  @ApiResponse({ status: 200, description: "Notification sent to all users" })
  async sendNotificationToAll(@Body() body: notificationsFirebaseWithoutToken) {
    return await this.firebaseService.sendNotificationToAll(
      body.title,
      body.body,
    );
  }

  @Post()
  @ApiOperation({ summary: "Send notification to specific token (Legacy)" })
  @ApiResponse({ status: 200, description: "Notification sent successfully" })
  async sendNotification(@Body() body: notificationsFirebase) {
    const payload = {
      notification: {
        title: body.title,
        body: body.body,
      },
      token: body.token,
    };

    return await this.firebaseService.sendNotification(payload);
  }

  @Post("send-to-subscribe")
  @ApiOperation({ summary: "Send notification to brand subscribers (Legacy)" })
  @ApiResponse({ status: 200, description: "Notification sent to subscribers" })
  async senNotificationToSubscribe(
    @Body() body: notificationFirebaseToSubscribe,
  ) {
    const payload = {
      notification: {
        title: body?.title,
        body: body?.body,
      },
    };
    return this.firebaseService.sendNotificationToSubscribe(
      payload,
      body?.uuid,
    );
  }

  // New Admin Panel endpoints

  @Post("admin/send")
  @UseGuards(AuthGuard, AdminGuard)
  @ApiSecurity("token")
  @ApiOperation({ summary: "Send notification with history tracking (Admin)" })
  @ApiResponse({
    status: 201,
    description: "Notification sent successfully with history",
    type: NotificationHistoryResponse,
  })
  async sendNotificationWithHistory(
    @Body() body: SendNotificationDto,
    @Req() req: Request,
  ) {
    return await this.firebaseService.sendNotificationWithHistory(
      body,
      (req as any)?.uuid,
    );
  }

  @Post("admin/create")
  @UseGuards(AuthGuard, AdminGuard)
  @ApiSecurity("token")
  @ApiOperation({ summary: "Create notification draft (Admin)" })
  @ApiResponse({
    status: 201,
    description: "Notification draft created successfully",
    type: NotificationHistoryResponse,
  })
  async createNotification(
    @Body() body: CreateNotificationDto,
    @Req() req: Request,
  ) {
    return await this.firebaseService.createNotificationHistory(
      body,
      (req as any)?.uuid,
    );
  }

  @Get("admin/history")
  @UseGuards(AuthGuard, AdminGuard)
  @ApiSecurity("token")
  @ApiOperation({ summary: "Get notification history with pagination (Admin)" })
  @ApiQuery({
    name: "type",
    required: false,
    enum: ["all_users", "brand_subscribers", "specific_user", "topic"],
  })
  @ApiQuery({
    name: "status",
    required: false,
    enum: ["pending", "sent", "failed", "partial"],
  })
  @ApiQuery({
    name: "search",
    required: false,
    description: "Search in title and body",
  })
  @ApiQuery({ name: "page", required: false, type: Number })
  @ApiQuery({ name: "limit", required: false, type: Number })
  @ApiQuery({
    name: "startDate",
    required: false,
    description: "Start date filter (YYYY-MM-DD)",
  })
  @ApiQuery({
    name: "endDate",
    required: false,
    description: "End date filter (YYYY-MM-DD)",
  })
  @ApiResponse({
    status: 200,
    description: "Notification history retrieved successfully",
    schema: {
      type: "object",
      properties: {
        total: { type: "number" },
        page: { type: "number" },
        limit: { type: "number" },
        totalPages: { type: "number" },
        data: {
          type: "array",
          items: { $ref: "#/components/schemas/NotificationHistoryResponse" },
        },
      },
    },
  })
  async getNotificationHistory(@Query() query: FindAllNotificationsDto) {
    return await this.firebaseService.findAllNotifications(query);
  }

  @Get("admin/history/:uuid")
  @UseGuards(AuthGuard, AdminGuard)
  @ApiSecurity("token")
  @ApiOperation({ summary: "Get specific notification by UUID (Admin)" })
  @ApiParam({ name: "uuid", description: "Notification UUID" })
  @ApiResponse({
    status: 200,
    description: "Notification details retrieved successfully",
    type: NotificationHistoryResponse,
  })
  @ApiResponse({ status: 404, description: "Notification not found" })
  async getNotificationById(@Param("uuid", ParseUUIDPipe) uuid: string) {
    return await this.firebaseService.findNotificationById(uuid);
  }

  @Patch("admin/history/:uuid")
  @UseGuards(AuthGuard, AdminGuard)
  @ApiSecurity("token")
  @ApiOperation({ summary: "Update notification draft (Admin)" })
  @ApiParam({ name: "uuid", description: "Notification UUID" })
  @ApiResponse({
    status: 200,
    description: "Notification updated successfully",
    type: NotificationHistoryResponse,
  })
  @ApiResponse({ status: 404, description: "Notification not found" })
  @ApiResponse({ status: 400, description: "Cannot update sent notification" })
  async updateNotification(
    @Param("uuid", ParseUUIDPipe) uuid: string,
    @Body() body: UpdateNotificationDto,
  ) {
    return await this.firebaseService.updateNotification(uuid, body);
  }

  @Delete("admin/history/:uuid")
  @UseGuards(AuthGuard, AdminGuard)
  @ApiSecurity("token")
  @ApiOperation({ summary: "Delete notification draft (Admin)" })
  @ApiParam({ name: "uuid", description: "Notification UUID" })
  @ApiResponse({
    status: 200,
    description: "Notification deleted successfully",
  })
  @ApiResponse({ status: 404, description: "Notification not found" })
  @ApiResponse({ status: 400, description: "Cannot delete sent notification" })
  async deleteNotification(@Param("uuid", ParseUUIDPipe) uuid: string) {
    return await this.firebaseService.deleteNotification(uuid);
  }

  @Get("admin/stats")
  @UseGuards(AuthGuard, AdminGuard)
  @ApiSecurity("token")
  @ApiOperation({ summary: "Get notification statistics (Admin)" })
  @ApiResponse({
    status: 200,
    description: "Notification statistics retrieved successfully",
    type: NotificationStatsDto,
  })
  async getNotificationStats() {
    return await this.firebaseService.getNotificationStats();
  }

  @Post("admin/send-draft/:uuid")
  @UseGuards(AuthGuard, AdminGuard)
  @ApiSecurity("token")
  @ApiOperation({ summary: "Send a draft notification (Admin)" })
  @ApiParam({ name: "uuid", description: "Notification UUID" })
  @ApiResponse({
    status: 200,
    description: "Draft notification sent successfully",
    type: NotificationHistoryResponse,
  })
  @ApiResponse({ status: 404, description: "Notification not found" })
  @ApiResponse({
    status: 400,
    description: "Cannot send already sent notification",
  })
  async sendDraftNotification(
    @Param("uuid", ParseUUIDPipe) uuid: string,
    @Req() req: Request,
  ) {
    const notification = await this.firebaseService.findNotificationById(uuid);

    if (notification.status !== "pending") {
      throw new Error("Cannot send notification that has already been sent");
    }

    const sendDto: SendNotificationDto = {
      title: notification.title,
      body: notification.body,
      type: notification.type,
      targetData: notification.targetData,
      additionalData: notification.additionalData,
      topic: notification.topic,
      scheduledFor: notification.scheduledFor,
    };

    return await this.firebaseService.sendNotificationWithHistory(
      sendDto,
      (req as any)?.uuid,
    );
  }
}
