import { Module } from "@nestjs/common";
import { SubscriptionController } from "./subscription.controller";
import { SubscriptionService } from "./subscription.service";
import { UtilProviders } from "src/utils/utilsProvider";

@Module({
  controllers: [SubscriptionController],
  providers: [SubscriptionService, ...UtilProviders],
})
export class SubscriptionModule {}
