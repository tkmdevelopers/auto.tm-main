import { Test, TestingModule } from "@nestjs/testing";
import { AdminsController } from "./admins.controller";
import { AdminGuard } from "../guards/admin.guard";
import { AuthGuard } from "../guards/auth.guard";
import { JwtService } from "@nestjs/jwt";
import { User } from '../auth/auth.entity';
import { AdminsService } from "./admins.service";
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


describe("AdminsController", () => {
  let controller: AdminsController;

  const mockJwtService = {
    verify: jest.fn(),
    sign: jest.fn(),
    verifyAsync: jest.fn(),
    signAsync: jest.fn(),
  };

  const mockUserRepository = {
    findOne: jest.fn(),
  };

  const mockAdminsService = {
    findOne: jest.fn(),
    updateAdmin: jest.fn(),
    deleteOne: jest.fn(),
    // Add other methods that AdminsController calls on AdminsService
  };


  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [AdminsController],
      providers: [
        { provide: AdminGuard, useClass: MockAdminGuard },
        { provide: AuthGuard, useClass: MockAuthGuard },
        { provide: JwtService, useValue: mockJwtService },
        { provide: "USERS_REPOSITORY", useValue: mockUserRepository },
        { provide: AdminsService, useValue: mockAdminsService },
      ],
    }).compile();

    controller = module.get<AdminsController>(AdminsController);
  });

  it("should be defined", () => {
    expect(controller).toBeDefined();
  });
});
