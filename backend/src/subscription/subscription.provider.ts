import { Subscriptions } from "./subscription.entity";

export const SubscriptionsProvider = [
  {
    provide: "SUBSCRIPTIONS_REPOSITORY",
    useValue: Subscriptions,
  },
];
