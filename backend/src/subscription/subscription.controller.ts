import {
  Body,
  Controller,
  Get,
  Param,
  ParseIntPipe,
  Post,
  Put,
  Query,
  Req,
  Res,
} from "@nestjs/common";
import { SubscriptionService } from "./subscription.service";
import { ApiTags } from "@nestjs/swagger";
import { Request, Response } from "express";
import {
  CreateSubscriptionDto,
  findAllSubscription,
  findOneSubscriptions,
  getAllOrdersSubscription,
  orderSubscriptionDto,
  UpdateSubscriptionDto,
} from "./subscription.dto";

@Controller({
  path: "subscription",
  version: "1",
})
@ApiTags("Post subscriptions & Functions")
export class SubscriptionController {
  constructor(private subscriptionService: SubscriptionService) {}

  @Get()
  async findAll(
    @Query() query: findAllSubscription,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    return this.subscriptionService.findAll(query, req, res);
  }
  @Get(":uuid")
  async findOne(
    @Param() param: findOneSubscriptions,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    return this.subscriptionService.findOne(param, req, res);
  }
  @Post()
  async create(
    @Body() body: CreateSubscriptionDto,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    return this.subscriptionService.create(body, req, res);
  }
  @Put(":id")
  update(
    @Param("id") id: string,
    @Body() dto: UpdateSubscriptionDto,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    return this.subscriptionService.update(id, dto, req, res);
  }
  @Post("order")
  async subscription_order(
    @Body() body: orderSubscriptionDto,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    return this.subscriptionService.order(body, req, res);
  }
  @Get("order")
  async get_all_subscription_order(
    @Query() query: getAllOrdersSubscription,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    return this.subscriptionService.getAllOrders(query, req, res);
  }
}
