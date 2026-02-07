import { Test, TestingModule } from "@nestjs/testing";
import { PostService } from "./post.service";
import { Models } from '../models/models.entity';
import { Posts } from './post.entity';
import { Comments } from '../comments/comments.entity';
import { Photo } from '../photo/photo.entity';
import { Video } from '../video/video.entity';
import { Categories } from '../categories/categories.entity';
import { Subscriptions } from '../subscription/subscription.entity';
import { User } from '../auth/auth.entity';
import { File } from '../file/file.entity';
import { Brands } from '../brands/brands.entity';

describe("PostService", () => {
  let service: PostService;

  const mockModelsRepository = {
    // Add mock methods as needed
    findOne: jest.fn(),
  };
  const mockPostsRepository = {
    // Add mock methods as needed
    findOne: jest.fn(),
    create: jest.fn(),
    findAll: jest.fn(),
  };
  const mockCommentsRepository = {
    // Add mock methods as needed
    findAll: jest.fn(),
  };
  const mockPhotoRepository = {
    // Add mock methods as needed
    create: jest.fn(),
  };
  const mockVideoRepository = {
    // Add mock methods as needed
    create: jest.fn(),
  };
  const mockCategoriesRepository = {
    // Add mock methods as needed
    findOne: jest.fn(),
  };
  const mockSubscriptionsRepository = {
    // Add mock methods as needed
    findOne: jest.fn(),
  };
  const mockUsersRepository = {
    // Add mock methods as needed
    findOne: jest.fn(),
  };
  const mockFileRepository = {
    // Add mock methods as needed
    create: jest.fn(),
  };
  const mockBrandsRepository = {
    // Add mock methods as needed
    findOne: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PostService,
        { provide: "MODELS_REPOSITORY", useValue: mockModelsRepository },
        { provide: "POSTS_REPOSITORY", useValue: mockPostsRepository },
        { provide: "COMMENTS_REPOSITORY", useValue: mockCommentsRepository },
        { provide: "PHOTO_REPOSITORY", useValue: mockPhotoRepository },
        { provide: "VIDEO_REPOSITORY", useValue: mockVideoRepository },
        { provide: "CATEGORIES_REPOSITORY", useValue: mockCategoriesRepository },
        { provide: "SUBSCRIPTIONS_REPOSITORY", useValue: mockSubscriptionsRepository },
        { provide: "USERS_REPOSITORY", useValue: mockUsersRepository },
        { provide: "FILE_REPOSITORY", useValue: mockFileRepository },
        { provide: "BRANDS_REPOSITORY", useValue: mockBrandsRepository },
      ],
    }).compile();

    service = module.get<PostService>(PostService);
  });

  it("should be defined", () => {
    expect(service).toBeDefined();
  });
});
