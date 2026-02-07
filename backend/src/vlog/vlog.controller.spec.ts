import { Test, TestingModule } from "@nestjs/testing";
import { VlogController } from "./vlog.controller";
import { AuthGuard } from "../guards/auth.guard";
import { JwtService } from "@nestjs/jwt";
import { User } from '../auth/auth.entity';
import { VlogService } from "./vlog.service";
import { CanActivate, ExecutionContext } from "@nestjs/common";

// Mock Guard Classes
class MockAuthGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean | Promise<boolean> | import("rxjs").Observable<boolean> {
    const request = context.switchToHttp().getRequest();
    request['uuid'] = 'mock-uuid'; // Set a mock uuid for downstream dependencies
    return true;
  }
}

describe("VlogController", () => {
  let controller: VlogController;

  const mockJwtService = {
    verify: jest.fn(),
    sign: jest.fn(),
    verifyAsync: jest.fn(),
    signAsync: jest.fn(),
  };

  const mockUserRepository = {
    findOne: jest.fn(),
  };

  const mockVlogService = {
    create: jest.fn(),
    findOne: jest.fn(),
    findAll: jest.fn(),
    update: jest.fn(),
    deleteOne: jest.fn(),
    // Add other methods that VlogController calls on VlogService
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [VlogController],
      providers: [
        { provide: AuthGuard, useClass: MockAuthGuard },
        { provide: JwtService, useValue: mockJwtService },
        { provide: "USERS_REPOSITORY", useValue: mockUserRepository },
        { provide: VlogService, useValue: mockVlogService },
      ],
    }).compile();

    controller = module.get<VlogController>(VlogController);
  });

  it("should be defined", () => {
    expect(controller).toBeDefined();
  });
});
