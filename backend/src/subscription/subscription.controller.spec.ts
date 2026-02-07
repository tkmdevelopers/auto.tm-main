import { Test, TestingModule } from "@nestjs/testing";
import { SubscriptionController } from "./subscription.controller";
import { SubscriptionService } from "./subscription.service"; // Import SubscriptionService

describe("SubscriptionController", () => {
  let controller: SubscriptionController;

  const mockSubscriptionService = {
    // Mock methods used by SubscriptionController on SubscriptionService
    subscribeToBrand: jest.fn(),
    unsubscribeFromBrand: jest.fn(),
    getSubscriptions: jest.fn(),
    // Add other methods as needed
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [SubscriptionController],
      providers: [
        {
          provide: SubscriptionService,
          useValue: mockSubscriptionService,
        },
      ],
    }).compile();

    controller = module.get<SubscriptionController>(SubscriptionController);
  });

  it("should be defined", () => {
    expect(controller).toBeDefined();
  });
});
