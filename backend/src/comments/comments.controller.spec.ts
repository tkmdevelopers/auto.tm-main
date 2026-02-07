import { Test, TestingModule } from "@nestjs/testing";
import { CommentsController } from "./comments.controller";
import { JwtService } from "@nestjs/jwt";
import { User } from '../auth/auth.entity';
import { CommentsService } from "./comments.service";
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


describe("CommentsController", () => {
  let controller: CommentsController;

  const mockJwtService = {
    verify: jest.fn(),
    sign: jest.fn(),
    verifyAsync: jest.fn(),
    signAsync: jest.fn(),
  };

  const mockUserRepository = {
    findOne: jest.fn(),
  };

  const mockCommentsService = {
    create: jest.fn(),
    findAll: jest.fn(),
    findOne: jest.fn(),
    update: jest.fn(),
    deleteOne: jest.fn(),
    // Add other methods that CommentsController calls on CommentsService
  };


  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [CommentsController],
      providers: [
        { provide: AuthGuard, useClass: MockAuthGuard }, // Use mock class
        { provide: JwtService, useValue: mockJwtService },
        { provide: "USERS_REPOSITORY", useValue: mockUserRepository },
        { provide: CommentsService, useValue: mockCommentsService },
      ],
    }).compile();

    controller = module.get<CommentsController>(CommentsController);
  });

  it("should be defined", () => {
    expect(controller).toBeDefined();
  });
});