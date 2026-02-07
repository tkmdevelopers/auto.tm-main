import { Test, TestingModule } from "@nestjs/testing";
import { CategoriesController } from "./categories.controller";
import { JwtService } from "@nestjs/jwt";
import { User } from '../auth/auth.entity';
import { CategoriesService } from "./categories.service";
import { CanActivate, ExecutionContext } from "@nestjs/common";

// Import the original guard for typing purposes
import { AuthGuard } from "../guards/auth.guard";

// Mock Guard Class
class MockAuthGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean | Promise<boolean> | import("rxjs").Observable<boolean> {
    const request = context.switchToHttp().getRequest();
    request['uuid'] = 'mock-uuid'; // Set a mock uuid for downstream dependencies
    return true;
  }
}


describe("CategoriesController", () => {
  let controller: CategoriesController;

  const mockJwtService = {
    verify: jest.fn(),
    sign: jest.fn(),
    verifyAsync: jest.fn(),
    signAsync: jest.fn(),
  };

  const mockUserRepository = {
    findOne: jest.fn(),
  };

  const mockCategoriesService = {
    create: jest.fn(),
    findAll: jest.fn(),
    findOne: jest.fn(),
    update: jest.fn(),
    deleteOne: jest.fn(),
    // Add other methods that CategoriesController calls on CategoriesService
  };


  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [CategoriesController],
      providers: [
        { provide: AuthGuard, useClass: MockAuthGuard }, // Use mock class
        { provide: JwtService, useValue: mockJwtService },
        { provide: "USERS_REPOSITORY", useValue: mockUserRepository },
        { provide: CategoriesService, useValue: mockCategoriesService },
      ],
    }).compile();

    controller = module.get<CategoriesController>(CategoriesController);
  });

  it("should be defined", () => {
    expect(controller).toBeDefined();
  });
});
