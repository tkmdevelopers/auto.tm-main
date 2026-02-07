import { Test, TestingModule } from "@nestjs/testing";
import { ModelsController } from "./models.controller";
import { JwtService } from "@nestjs/jwt";
import { User } from '../auth/auth.entity';
import { ModelsService } from "./models.service";
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


describe("ModelsController", () => {
  let controller: ModelsController;

  const mockJwtService = {
    verify: jest.fn(),
    sign: jest.fn(),
    verifyAsync: jest.fn(),
    signAsync: jest.fn(),
  };

  const mockUserRepository = {
    findOne: jest.fn(),
  };

  const mockModelsService = {
    create: jest.fn(),
    findAll: jest.fn(),
    findOne: jest.fn(),
    update: jest.fn(),
    deleteOne: jest.fn(),
    // Add other methods that ModelsController calls on ModelsService
  };


  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [ModelsController],
      providers: [
        { provide: AdminGuard, useClass: MockAdminGuard }, // Use mock class
        { provide: AuthGuard, useClass: MockAuthGuard }, // Use mock class
        { provide: JwtService, useValue: mockJwtService },
        { provide: "USERS_REPOSITORY", useValue: mockUserRepository },
        { provide: ModelsService, useValue: mockModelsService },
      ],
    }).compile();

    controller = module.get<ModelsController>(ModelsController);
  });

  it("should be defined", () => {
    expect(controller).toBeDefined();
  });
});