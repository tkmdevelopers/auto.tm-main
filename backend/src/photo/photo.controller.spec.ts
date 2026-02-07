import { Test, TestingModule } from "@nestjs/testing";
import { PhotoController } from "./photo.controller";
import { JwtService } from "@nestjs/jwt";
import { User } from '../auth/auth.entity';
import { PhotoService } from "./photo.service";
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


describe("PhotoController", () => {
  let controller: PhotoController;

  const mockJwtService = {
    verify: jest.fn(),
    sign: jest.fn(),
    verifyAsync: jest.fn(),
    signAsync: jest.fn(),
  };

  const mockUserRepository = {
    findOne: jest.fn(),
  };

  const mockPhotoService = {
    create: jest.fn(),
    findAll: jest.fn(),
    findOne: jest.fn(),
    update: jest.fn(),
    deleteOne: jest.fn(),
    // Add other methods that PhotoController calls on PhotoService
  };


  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [PhotoController],
      providers: [
        { provide: AuthGuard, useClass: MockAuthGuard }, // Use mock class
        { provide: JwtService, useValue: mockJwtService },
        { provide: "USERS_REPOSITORY", useValue: mockUserRepository },
        { provide: PhotoService, useValue: mockPhotoService },
      ],
    }).compile();

    controller = module.get<PhotoController>(PhotoController);
  });

  it("should be defined", () => {
    expect(controller).toBeDefined();
  });
});
