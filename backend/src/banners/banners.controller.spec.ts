import { Test, TestingModule } from "@nestjs/testing";
import { BannersController } from "./banners.controller";
import { AdminGuard } from "../guards/admin.guard";
import { AuthGuard } from "../guards/auth.guard";
import { JwtService } from "@nestjs/jwt";
import { User } from '../auth/auth.entity';
import { BannersService } from "./banners.service";
import { CanActivate, ExecutionContext } from "@nestjs/common";

// Mock Guard Classes
class MockAdminGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean | Promise<boolean> | import("rxjs").Observable<boolean> {
    return true;
  }
}

class MockAuthGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean | Promise<boolean> | import("rxjs").Observable<boolean> {
    const request = context.switchToHttp().getRequest();
    request['uuid'] = 'mock-uuid'; // Set a mock uuid for downstream dependencies
    return true;
  }
}


describe("BannersController", () => {
  let controller: BannersController;

  const mockJwtService = {
    verify: jest.fn(),
    sign: jest.fn(),
    verifyAsync: jest.fn(),
    signAsync: jest.fn(),
  };

  const mockUserRepository = {
    findOne: jest.fn(),
  };

  const mockBannersService = {
    create: jest.fn(),
    findAll: jest.fn(),
    findOne: jest.fn(),
    update: jest.fn(),
    deleteOne: jest.fn(),
    // Add other methods that BannersController calls on BannersService
  };


  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [BannersController],
      providers: [
        { provide: AdminGuard, useClass: MockAdminGuard },
        { provide: AuthGuard, useClass: MockAuthGuard },
        { provide: JwtService, useValue: mockJwtService },
        { provide: "USERS_REPOSITORY", useValue: mockUserRepository },
        { provide: BannersService, useValue: mockBannersService },
      ],
    }).compile();

    controller = module.get<BannersController>(BannersController);
  });

  it("should be defined", () => {
    expect(controller).toBeDefined();
  });
});
