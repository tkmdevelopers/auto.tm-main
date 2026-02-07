import { Test, TestingModule } from "@nestjs/testing";
import { SubscriptionService } from "./subscription.service";
import { Subscriptions } from './subscription.entity'; // Import Subscriptions entity
import { Photo } from '../photo/photo.entity'; // Import Photo entity

describe("SubscriptionService", () => {
  let service: SubscriptionService;

  const mockSubscriptionsRepository = {
    create: jest.fn(),
    findOne: jest.fn(),
    findAll: jest.fn(),
    update: jest.fn(), // Added update method
    // Add any other methods that SubscriptionService calls on the Subscriptions repository
  };

  const mockPhotoRepository = {
    create: jest.fn(),
    destroy: jest.fn(),
    // Add any other methods that SubscriptionService calls on the Photo repository
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        SubscriptionService,
        {
          provide: "SUBSCRIPTIONS_REPOSITORY", // This token should match the injection token in SubscriptionService
          useValue: mockSubscriptionsRepository,
        },
        {
          provide: "PHOTO_REPOSITORY", // This token should match the injection token in SubscriptionService
          useValue: mockPhotoRepository,
        },
      ],
    }).compile();

    service = module.get<SubscriptionService>(SubscriptionService);
  });

  it("should be defined", () => {
    expect(service).toBeDefined();
  });
});
