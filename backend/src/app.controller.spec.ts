import { Test, TestingModule } from "@nestjs/testing";
import { AppController } from "./app.controller";
import { AppService } from "./app.service";
import { AuthGuard } from "./guards/auth.guard"; // Import AuthGuard
import { JwtService } from "@nestjs/jwt"; // Import JwtService
import { User } from "./auth/auth.entity"; // Import User entity

describe("AppController", () => {
  let appController: AppController;

  const mockAppService = {
    getHello: jest.fn(() => "Hello World!"),
  };

  const mockAuthGuard = {
    canActivate: jest.fn(() => true), // Mock the canActivate method
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

  beforeEach(async () => {
    const app: TestingModule = await Test.createTestingModule({
      controllers: [AppController],
      providers: [
        {
          provide: AppService,
          useValue: mockAppService,
        },
        {
          provide: AuthGuard,
          useValue: mockAuthGuard,
        },
        {
          provide: JwtService,
          useValue: mockJwtService,
        },
        {
          provide: "USERS_REPOSITORY", // This token should match the injection token
          useValue: mockUserRepository,
        },
      ],
    }).compile();

    appController = app.get<AppController>(AppController);
  });

  describe("root", () => {
    it('should return "Hello World!"', () => {
      expect(appController.getHello()).toBe("Hello World!");
    });
  });
});
