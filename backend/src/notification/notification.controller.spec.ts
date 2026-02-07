import { Test, TestingModule } from "@nestjs/testing";
import { NotificationsController } from "./notification.controller";
import { AuthGuard } from "../guards/auth.guard"; // Import AuthGuard
import { JwtService } from "@nestjs/jwt"; // Import JwtService
import { User } from '../auth/auth.entity'; // Import User entity
import { NotificationService } from "./notification.service"; // Import NotificationService
import { AdminGuard } from "src/guards/admin.guard";


describe("NotificationsController", () => {
  let controller: NotificationsController;

  const mockAuthGuard = {
    canActivate: jest.fn(() => true), // Mock the canActivate method
  };

  const mockAdminGuard = {
    canActivate: jest.fn(() => true),
  };

  const mockJwtService = {
    // Mock methods used by AuthGuard or any other service on JwtService
    verify: jest.fn(),
    sign: jest.fn(),
  };

  const mockUserRepository = {
    // Mock methods used by AuthGuard or any other service on User entity
    findOne: jest.fn(),
  };

  const mockNotificationService = {
    // Mock methods used by NotificationsController on NotificationService
    sendNotificationToAll: jest.fn(),
    sendNotification: jest.fn(),
    senNotificationToSubscribe: jest.fn(),
    sendNotificationWithHistory: jest.fn(),
    createNotificationHistory: jest.fn(),
    findAllNotifications: jest.fn(),
    findNotificationById: jest.fn(),
    updateNotification: jest.fn(),
    deleteNotification: jest.fn(),
    getNotificationStats: jest.fn(),
    // Add other methods as needed
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [NotificationsController],
      providers: [
        {
          provide: AuthGuard,
          useValue: mockAuthGuard,
        },
        {
          provide: AdminGuard,
          useValue: mockAdminGuard,
        },
        {
          provide: JwtService,
          useValue: mockJwtService,
        },
        {
          provide: "USERS_REPOSITORY", // This token should match the injection token
          useValue: mockUserRepository,
        },
        {
          provide: NotificationService,
          useValue: mockNotificationService,
        },
      ],
    }).compile();

    controller = module.get<NotificationsController>(NotificationsController);
  });

  it("should be defined", () => {
    expect(controller).toBeDefined();
  });
});
