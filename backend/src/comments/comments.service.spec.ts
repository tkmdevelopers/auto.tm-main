import { Test, TestingModule } from "@nestjs/testing";
import { CommentsService } from "./comments.service";
import { User } from "../../src/auth/auth.entity"; // Import User entity
import { Comments } from "./comments.entity"; // Import Comments entity
import { Posts } from "../../src/post/post.entity"; // Import Posts entity

describe("CommentsService", () => {
  let service: CommentsService;

  const mockUserRepository = {
    // Mock methods used by CommentsService on User entity
    findOne: jest.fn(),
    // Add other methods as needed
  };

  const mockCommentsRepository = {
    // Mock methods used by CommentsService on Comments entity
    create: jest.fn(),
    findOne: jest.fn(),
    findAll: jest.fn(),
    destroy: jest.fn(),
    // Add other methods as needed
  };

  const mockPostsRepository = {
    // Mock methods used by CommentsService on Posts entity
    findOne: jest.fn(),
    // Add other methods as needed
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CommentsService,
        {
          provide: "USERS_REPOSITORY",
          useValue: mockUserRepository,
        },
        {
          provide: "COMMENTS_REPOSITORY",
          useValue: mockCommentsRepository,
        },
        {
          provide: "POSTS_REPOSITORY",
          useValue: mockPostsRepository,
        },
      ],
    }).compile();

    service = module.get<CommentsService>(CommentsService);
  });

  it("should be defined", () => {
    expect(service).toBeDefined();
  });
});
