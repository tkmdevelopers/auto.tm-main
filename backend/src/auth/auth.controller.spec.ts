import { Test, TestingModule } from "@nestjs/testing";
import { AuthController } from "./auth.controller";
import { AuthService } from "./auth.service";
import { JwtService } from "@nestjs/jwt";
import { RefreshGuard } from "../guards/refresh.guard";
import { AuthGuard } from "../guards/auth.guard";
import { AdminGuard } from "../guards/admin.guard";
import { User } from './auth.entity'; // Import User entity

describe("AuthController", () => {
  let controller: AuthController;

  const mockAuthService = {
    login: jest.fn(),
    refreshToken: jest.fn(),
    register: jest.fn(),
    // Add other methods as needed
  };

  const mockJwtService = {
    verify: jest.fn(),
    sign: jest.fn(),
    verifyAsync: jest.fn(), // AuthGuard uses verifyAsync
    signAsync: jest.fn(),
  };

  const mockUserRepository = {
    findOne: jest.fn(), // AuthGuard uses findOne
    // Add other methods as needed
  };

  // Mock guards as classes or provide instances with canActivate
  const mockAuthGuard = { canActivate: jest.fn(() => true) };
  const mockAdminGuard = { canActivate: jest.fn(() => true) };
  const mockRefreshGuard = { canActivate: jest.fn(() => true) };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [AuthController],
      providers: [
        {
          provide: AuthService,
          useValue: mockAuthService,
        },
        {
          provide: JwtService,
          useValue: mockJwtService,
        },
        {
          provide: "USERS_REPOSITORY", // Provide USERS_REPOSITORY at top level
          useValue: mockUserRepository,
        },
        {
          provide: RefreshGuard,
          useValue: mockRefreshGuard,
        },
        {
          provide: AuthGuard,
          useValue: mockAuthGuard,
        },
        {
          provide: AdminGuard,
          useValue: mockAdminGuard,
        },
      ],
    }).compile();

    controller = module.get<AuthController>(AuthController);
  });

  it("should be defined", () => {
    expect(controller).toBeDefined();
  });
});
