import { Inject, Injectable } from "@nestjs/common";
import { Subscriptions } from "./subscription.entity";
import { Request, Response } from "express";
import {
  CreateSubscriptionDto,
  findAllSubscription,
  findOneSubscriptions,
  getAllOrdersSubscription,
  orderSubscriptionDto,
  UpdateSubscriptionDto,
} from "./subscription.dto";
import { v4 as uuidV4 } from "uuid";
import { Photo } from "src/photo/photo.entity";
import { SubscriptionOrder } from "./subscription_order.entity";
import { Op } from "sequelize";

@Injectable()
export class SubscriptionService {
  constructor(
    @Inject("SUBSCRIPTIONS_REPOSITORY")
    private subscription: typeof Subscriptions,
    @Inject("PHOTO_REPOSITORY")
    private photo: typeof Photo,
  ) {}

  async findAll(query: findAllSubscription, req: Request, res: Response) {
    try {
      const {
        offset = 0,
        limit = 10,
        sortBy = "createdAt",
        order = "asc",
      } = query;

      const result = await this.subscription.findAll({
        offset,
        limit,
        order: [[sortBy, order]],
        include: ["photo"],
      });

      return res.status(200).json(result);
    } catch (error) {
      console.error(error);
      return res.status(500).json({ message: "Internal server error", error });
    }
  }
  async findOne(param: findOneSubscriptions, req: Request, res: Response) {
    try {
      const { uuid } = param;

      const result = await this.subscription.findOne({
        where: {
          uuid,
        },
        include: ["photo"],
      });

      return res.status(200).json(result);
    } catch (error) {
      console.error(error);
      return res.status(500).json({ message: "Internal server error", error });
    }
  }
  async create(body: CreateSubscriptionDto, req: Request, res: Response) {
    try {
      const { color, description, name, price, priority } = body;
      const newSubscription = await this.subscription.create({
        uuid: uuidV4(),
        color,
        priority,
        description,
        name,
        price,
      });
      await this.photo.create({
        uuid: uuidV4(),
        subscriptionId: newSubscription.uuid,
      });
      return res.status(201).json({
        message: "Subscription created successfully",
        data: newSubscription,
      });
    } catch (error) {
      console.error("Error creating subscription:", error);
      return res.status(500).json({
        message: "Failed to create subscription",
        error: error?.message || error,
      });
    }
  }
  async update(
    uuid: string,
    dto: UpdateSubscriptionDto,
    req: Request,
    res: Response,
  ) {
    try {
      const subscription = await this.subscription.findOne({
        where: { uuid },
      });

      if (!subscription) {
        return res.status(404).json({ message: "Subscription not found" });
      }

      await subscription.update(dto);

      return res.status(200).json({
        message: "Subscription updated successfully",
        uuid: subscription?.uuid,
      });
    } catch (error) {
      console.error("Error updating subscription:", error);
      return res.status(500).json({
        message: "Failed to update subscription",
        error: error?.message || error,
      });
    }
  }

  async order(body: orderSubscriptionDto, req: Request, res: Response) {
    try {
      const { location, phone, subscriptionId } = body;
      const order = await SubscriptionOrder.create({
        uuid: uuidV4(),
        location,
        phone,
        status: "Pending",
        subscriptionId,
      });
      return res.status(200).json({
        message: "Subscription updated successfully",
        data: order,
      });
    } catch (error) {
      console.error("Error updating subscription:", error);
      return res.status(500).json({
        message: "Failed to update subscription",
        error: error?.message || error,
      });
    }
  }
  async getAllOrders(
    query: getAllOrdersSubscription,
    req: Request,
    res: Response,
  ) {
    try {
      const {
        offset = 0,
        limit = 10,
        sortBy = "createdAt",
        order = "asc",
        location = "",
        status = "Pending",
      } = query;
      const result = await SubscriptionOrder.findAll({
        offset,
        limit,
        order: [[sortBy, order]],
        include: ["subscription"],
        where: {
          location: {
            [Op.iLike]: `%${location}%`,
          },
          status,
        },
      });

      return res.status(200).json(result);
    } catch (error) {
      console.error(error);
      return res.status(500).json({ message: "Internal server error", error });
    }
  }
}
