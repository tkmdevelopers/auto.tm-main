import { HttpException, HttpStatus, Injectable, Inject } from "@nestjs/common";
import { ServiceAccount } from "firebase-admin";
import * as admin from "firebase-admin";
import {
  notificationFirebaseToSubscribe,
  CreateNotificationDto,
  UpdateNotificationDto,
  FindAllNotificationsDto,
  SendNotificationDto,
  NotificationStatsDto,
} from "./notification.dto";
import {
  NotificationHistory,
  NotificationType,
  NotificationStatus,
} from "./notification.entity";
import { User } from "src/auth/auth.entity";
import { Brands } from "src/brands/brands.entity";
import { Op } from "sequelize";
import { v4 as uuidv4 } from "uuid";

@Injectable()
export class NotificationService {
  constructor(
    @Inject("NOTIFICATION_HISTORY_REPOSITORY")
    private notificationHistoryRepo: typeof NotificationHistory,
    @Inject("USERS_REPOSITORY")
    private usersRepo: typeof User,
    @Inject("BRANDS_REPOSITORY")
    private brandsRepo: typeof Brands,
  ) {
    const serviceAccount: ServiceAccount = {
      projectId: process.env.FIREBASE_PROJECT_ID,
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, "\n"),
    };

    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
  }

  async sendNotification(payload: any) {
    try {
      const response = await admin.messaging().send(payload);
      console.log("Successfully sent message:", response);
      return { message: "Notification sent successfully", response };
    } catch (error) {
      console.error("Error sending message:", error);
      throw new HttpException(
        "Failed to send notification",
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  async sendNotificationToAll(title: string, body: string) {
    const message = {
      notification: {
        title: title,
        body: body,
      },
      topic: "all",
    };

    try {
      const response = await admin.messaging().send(message);
      console.log("Successfully sent message:", response);
      return {
        message: "Notification sent to all users successfully",
        response,
      };
    } catch (error) {
      console.error("Error sending message:", error);
      throw new HttpException(
        "Failed to send notification to all users",
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  async sendNotificationToSubscribe(payload: any, uuid: string) {
    try {
      const { title, body } = payload?.notification;
      console.log(payload);
      console.log("Finding brands with uuid:", uuid);
      const brands = await this.brandsRepo.findAll({
        where: { uuid },
        include: [{ model: User, attributes: ["uuid", "firebaseToken"] }],
        attributes: ["uuid"],
      });

      if (!brands || brands.length === 0) {
        console.log("No brands found");
        throw new HttpException("Not found", HttpStatus.NOT_FOUND);
      }

      let successfulDeliveries = 0;
      let failedDeliveries = 0;
      const deliveryDetails: any[] = [];

      for (const brand of brands) {
        console.log("Processing brand:", brand.uuid);
        if (brand.users && brand.users.length > 0) {
          for (const user of brand.users) {
            console.log("Checking user:", user.uuid);
            if (user.firebaseToken) {
              try {
                const response = await admin.messaging().send({
                  notification: { body, title },
                  token: user.firebaseToken,
                });
                console.log("Successfully sent message:", response);
                successfulDeliveries++;
                deliveryDetails.push({
                  userId: user.uuid,
                  status: "success",
                  response,
                });
              } catch (error) {
                console.error("Error sending message:", error);
                failedDeliveries++;
                deliveryDetails.push({
                  userId: user.uuid,
                  status: "failed",
                  error: error.message,
                });
              }
            } else {
              console.log("⚠️ No firebaseToken for user:", user.uuid);
              failedDeliveries++;
              deliveryDetails.push({
                userId: user.uuid,
                status: "failed",
                error: "No firebase token",
              });
            }
          }
        } else {
          console.log("⚠️ Brand has no users:", brand.uuid);
        }
      }

      return {
        message: "Notifications attempted for all users",
        successfulDeliveries,
        failedDeliveries,
        deliveryDetails,
      };
    } catch (error) {
      console.error("🔥 Unexpected error:", error.message || error);
      throw new HttpException(
        "Failed to send notifications",
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  // New methods for notification history and admin panel

  async createNotificationHistory(
    createDto: CreateNotificationDto,
    sentBy: string,
  ) {
    try {
      const notification = await this.notificationHistoryRepo.create({
        uuid: uuidv4(),
        title: createDto.title,
        body: createDto.body,
        type: createDto.type,
        targetData: createDto.targetData || {},
        additionalData: createDto.additionalData || {},
        topic: createDto.topic,
        scheduledFor: createDto.scheduledFor,
        isScheduled: createDto.isScheduled || false,
        sentBy,
        status: NotificationStatus.PENDING,
        totalRecipients: 0,
        successfulDeliveries: 0,
        failedDeliveries: 0,
        deliveryDetails: {},
      });

      return notification;
    } catch (error) {
      console.error("Error creating notification history:", error);
      throw new HttpException(
        "Failed to create notification history",
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  async sendNotificationWithHistory(
    sendDto: SendNotificationDto,
    sentBy: string,
  ) {
    try {
      // Create notification history record
      const notificationHistory = await this.createNotificationHistory(
        sendDto,
        sentBy,
      );

      let deliveryResult;
      let status = NotificationStatus.SENT;
      let errorMessage = null;

      // Send notification based on type
      switch (sendDto.type) {
        case NotificationType.ALL_USERS:
          try {
            await this.sendNotificationToAll(sendDto.title, sendDto.body);
            deliveryResult = { message: "Sent to all users" };
          } catch (error) {
            status = NotificationStatus.FAILED;
            errorMessage = error.message;
            deliveryResult = { error: error.message };
          }
          break;

        case NotificationType.BRAND_SUBSCRIBERS:
          if (!sendDto.targetData?.brandId) {
            throw new HttpException(
              "Brand ID is required",
              HttpStatus.BAD_REQUEST,
            );
          }
          try {
            const result = await this.sendNotificationToSubscribe(
              { notification: { title: sendDto.title, body: sendDto.body } },
              sendDto.targetData.brandId,
            );
            deliveryResult = result;
            if (
              result.failedDeliveries > 0 &&
              result.successfulDeliveries > 0
            ) {
              status = NotificationStatus.PARTIAL;
            } else if (result.failedDeliveries > 0) {
              status = NotificationStatus.FAILED;
            }
          } catch (error) {
            status = NotificationStatus.FAILED;
            errorMessage = error.message;
            deliveryResult = { error: error.message };
          }
          break;

        case NotificationType.SPECIFIC_USER:
          if (!sendDto.targetData?.userId) {
            throw new HttpException(
              "User ID is required",
              HttpStatus.BAD_REQUEST,
            );
          }
          try {
            const user = await this.usersRepo.findByPk(
              sendDto.targetData.userId,
            );
            if (!user || !user.firebaseToken) {
              throw new HttpException(
                "User not found or no firebase token",
                HttpStatus.NOT_FOUND,
              );
            }
            await this.sendNotification({
              notification: { title: sendDto.title, body: sendDto.body },
              token: user.firebaseToken,
            });
            deliveryResult = {
              message: "Sent to specific user",
              userId: user.uuid,
            };
          } catch (error) {
            status = NotificationStatus.FAILED;
            errorMessage = error.message;
            deliveryResult = { error: error.message };
          }
          break;

        case NotificationType.TOPIC:
          if (!sendDto.topic) {
            throw new HttpException(
              "Topic is required",
              HttpStatus.BAD_REQUEST,
            );
          }
          try {
            await admin.messaging().send({
              notification: { title: sendDto.title, body: sendDto.body },
              topic: sendDto.topic,
            });
            deliveryResult = { message: "Sent to topic", topic: sendDto.topic };
          } catch (error) {
            status = NotificationStatus.FAILED;
            errorMessage = error.message;
            deliveryResult = { error: error.message };
          }
          break;

        default:
          throw new HttpException(
            "Invalid notification type",
            HttpStatus.BAD_REQUEST,
          );
      }

      // Update notification history with results
      await this.notificationHistoryRepo.update(
        {
          status,
          errorMessage,
          deliveryDetails: deliveryResult,
          totalRecipients: Math.round(
            Number(deliveryResult.totalRecipients) || 1,
          ),
          successfulDeliveries: Math.round(
            Number(deliveryResult.successfulDeliveries) || 1,
          ),
          failedDeliveries: Math.round(
            Number(deliveryResult.failedDeliveries) || 0,
          ),
        },
        { where: { uuid: notificationHistory.uuid } },
      );

      return {
        message: "Notification sent successfully",
        notificationId: notificationHistory.uuid,
        status,
        deliveryResult,
      };
    } catch (error) {
      console.error("Error sending notification with history:", error);
      throw new HttpException(
        error.message || "Failed to send notification",
        error.status || HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  async findAllNotifications(query: FindAllNotificationsDto) {
    try {
      const {
        type,
        status,
        search,
        sortBy = "createdAt",
        sortOrder = "DESC",
        page = 1,
        limit = 10,
        startDate,
        endDate,
      } = query;

      const where: any = {};

      if (type) where.type = type;
      if (status) where.status = status;

      if (search) {
        where[Op.or] = [
          { title: { [Op.iLike]: `%${search}%` } },
          { body: { [Op.iLike]: `%${search}%` } },
        ];
      }

      if (startDate || endDate) {
        where.createdAt = {};
        if (startDate) where.createdAt[Op.gte] = new Date(startDate);
        if (endDate) where.createdAt[Op.lte] = new Date(endDate);
      }

      const offset = (page - 1) * limit;

      const notifications = await this.notificationHistoryRepo.findAndCountAll({
        where,
        order: [[sortBy, sortOrder]],
        offset,
        limit,
        include: [
          { model: User, as: "sender", attributes: ["uuid", "name", "email"] },
        ],
      });

      return {
        total: notifications.count,
        page,
        limit,
        totalPages: Math.ceil(notifications.count / limit),
        data: notifications.rows,
      };
    } catch (error) {
      console.error("Error finding notifications:", error);
      throw new HttpException(
        "Failed to fetch notifications",
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  async findNotificationById(uuid: string) {
    try {
      const notification = await this.notificationHistoryRepo.findOne({
        where: { uuid },
        include: [
          { model: User, as: "sender", attributes: ["uuid", "name", "email"] },
        ],
      });

      if (!notification) {
        throw new HttpException("Notification not found", HttpStatus.NOT_FOUND);
      }

      return notification;
    } catch (error) {
      if (error.status) throw error;
      console.error("Error finding notification:", error);
      throw new HttpException(
        "Failed to fetch notification",
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  async updateNotification(uuid: string, updateDto: UpdateNotificationDto) {
    try {
      const notification = await this.notificationHistoryRepo.findOne({
        where: { uuid },
      });

      if (!notification) {
        throw new HttpException("Notification not found", HttpStatus.NOT_FOUND);
      }

      if (notification.status !== NotificationStatus.PENDING) {
        throw new HttpException(
          "Cannot update notification that has already been sent",
          HttpStatus.BAD_REQUEST,
        );
      }

      await this.notificationHistoryRepo.update(updateDto, { where: { uuid } });

      return await this.findNotificationById(uuid);
    } catch (error) {
      if (error.status) throw error;
      console.error("Error updating notification:", error);
      throw new HttpException(
        "Failed to update notification",
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  async deleteNotification(uuid: string) {
    try {
      const notification = await this.notificationHistoryRepo.findOne({
        where: { uuid },
      });

      if (!notification) {
        throw new HttpException("Notification not found", HttpStatus.NOT_FOUND);
      }

      if (notification.status !== NotificationStatus.PENDING) {
        throw new HttpException(
          "Cannot delete notification that has already been sent",
          HttpStatus.BAD_REQUEST,
        );
      }

      await this.notificationHistoryRepo.destroy({ where: { uuid } });

      return { message: "Notification deleted successfully" };
    } catch (error) {
      if (error.status) throw error;
      console.error("Error deleting notification:", error);
      throw new HttpException(
        "Failed to delete notification",
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  async getNotificationStats(): Promise<NotificationStatsDto> {
    try {
      const [
        totalNotifications,
        totalRecipients,
        totalSuccessfulDeliveries,
        totalFailedDeliveries,
        notificationsByType,
        notificationsByStatus,
      ] = await Promise.all([
        this.notificationHistoryRepo.count(),
        this.notificationHistoryRepo.sum("totalRecipients"),
        this.notificationHistoryRepo.sum("successfulDeliveries"),
        this.notificationHistoryRepo.sum("failedDeliveries"),
        this.notificationHistoryRepo.findAll({
          attributes: [
            "type",
            [this.notificationHistoryRepo.sequelize!.fn("COUNT", "*"), "count"],
          ],
          group: ["type"],
        }),
        this.notificationHistoryRepo.findAll({
          attributes: [
            "status",
            [this.notificationHistoryRepo.sequelize!.fn("COUNT", "*"), "count"],
          ],
          group: ["status"],
        }),
      ]);

      const successRate =
        totalRecipients > 0
          ? Math.round(
              (Number(totalSuccessfulDeliveries) / Number(totalRecipients)) *
                100,
            )
          : 0;

      const typeStats = {};
      notificationsByType.forEach((item: any) => {
        typeStats[item.type] = parseInt(item.getDataValue("count"));
      });

      const statusStats = {};
      notificationsByStatus.forEach((item: any) => {
        statusStats[item.status] = parseInt(item.getDataValue("count"));
      });

      return {
        totalNotifications,
        totalRecipients: Math.round(Number(totalRecipients) || 0),
        totalSuccessfulDeliveries: Math.round(
          Number(totalSuccessfulDeliveries) || 0,
        ),
        totalFailedDeliveries: Math.round(Number(totalFailedDeliveries) || 0),
        successRate,
        notificationsByType: typeStats,
        notificationsByStatus: statusStats,
      };
    } catch (error) {
      console.error("Error getting notification stats:", error);
      throw new HttpException(
        "Failed to get notification statistics",
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }
}
