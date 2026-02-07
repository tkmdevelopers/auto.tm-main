import { Test, TestingModule } from "@nestjs/testing";
import { PostController } from "./post.controller";
import { AuthGuard } from "../guards/auth.guard"; // Import AuthGuard
import { JwtService } from "@nestjs/jwt"; // Import JwtService
import { User } from '../auth/auth.entity'; // Import User entity
import { PostService } from "./post.service"; // Import PostService

describe("PostController", () => {
  let controller: PostController;

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

  const mockPostService = {
    // Mock methods used by PostController on PostService
    findAll: jest.fn(),
    createPost: jest.fn(),
    // Add other methods as needed
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [PostController],
      providers: [
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
        {
          provide: PostService,
          useValue: mockPostService,
        },
      ],
    }).compile();

    controller = module.get<PostController>(PostController);
  });

  it("should be defined", () => {
    expect(controller).toBeDefined();
  });
});
