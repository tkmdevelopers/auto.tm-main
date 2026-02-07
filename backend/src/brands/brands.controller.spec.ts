import { Test, TestingModule } from "@nestjs/testing";
import { BrandsController } from "./brands.controller";
import { JwtService } from "@nestjs/jwt";
import { User } from '../auth/auth.entity';
import { BrandsService } from "./brands.service";
import { CanActivate, ExecutionContext } from "@nestjs/common";

// Import the original guards for typing purposes
import { AdminGuard } from "../guards/admin.guard";
import { AuthGuard } from "../guards/auth.guard";

// Mock Guard Classes - these replace the original guards during testing
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


describe("BrandsController", () => {
  let controller: BrandsController;

  const mockJwtService = {
    verify: jest.fn(),
    sign: jest.fn(),
    verifyAsync: jest.fn(),
    signAsync: jest.fn(),
  };

  const mockUserRepository = {
    findOne: jest.fn(),
  };

  const mockBrandsService = {
    create: jest.fn(),
    findAll: jest.fn(),
    findOne: jest.fn(),
    update: jest.fn(),
    deleteOne: jest.fn(),
    // Add other methods that BrandsController calls on BrandsService
  };


  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [BrandsController],
      providers: [
        { provide: AdminGuard, useClass: MockAdminGuard }, // Use mock class
        { provide: AuthGuard, useClass: MockAuthGuard }, // Use mock class
        { provide: JwtService, useValue: mockJwtService },
        { provide: "USERS_REPOSITORY", useValue: mockUserRepository },
        { provide: BrandsService, useValue: mockBrandsService },
      ],
    }).compile();

    controller = module.get<BrandsController>(BrandsController);
  });

  it("should be defined", () => {
    expect(controller).toBeDefined();
  });
});