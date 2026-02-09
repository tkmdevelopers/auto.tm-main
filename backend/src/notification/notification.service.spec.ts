jest.mock("firebase-admin"); // Mock firebase-admin

import { Test, TestingModule } from "@nestjs/testing";
import { NotificationService } from "./notification.service";
import { User } from "../../src/auth/auth.entity"; // Import User entity
import { Brands } from "../../src/brands/brands.entity"; // Import Brands entity
import { NotificationHistory } from "./notification.entity"; // Import NotificationHistory entity

describe("NotificationService", () => {
  let service: NotificationService;

  const mockUserRepository = {
    // Mock methods used by NotificationService on User entity
    findOne: jest.fn(),
    // Add other methods as needed
  };

  const mockBrandsRepository = {
    // Mock methods used by NotificationService on Brands entity
    findOne: jest.fn(),
    // Add other methods as needed
  };

  const mockNotificationHistoryRepository = {
    // Mock methods used by NotificationService on NotificationHistory entity
    create: jest.fn(),
    findOne: jest.fn(),
    findAll: jest.fn(),
    // Add other methods as needed
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        NotificationService,
        {
          provide: "USERS_REPOSITORY",
          useValue: mockUserRepository,
        },
        {
          provide: "BRANDS_REPOSITORY",
          useValue: mockBrandsRepository,
        },
        {
          provide: "NOTIFICATION_HISTORY_REPOSITORY",
          useValue: mockNotificationHistoryRepository,
        },
      ],
    }).compile();

    service = module.get<NotificationService>(NotificationService);
  });

  it("should be defined", () => {
    expect(service).toBeDefined();
  });
});
