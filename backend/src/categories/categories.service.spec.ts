import { Test, TestingModule } from "@nestjs/testing";
import { CategoriesService } from "./categories.service";
import { Photo } from '../../src/photo/photo.entity'; // Import Photo entity
import { Posts } from '../../src/post/post.entity'; // Import Posts entity
import { Categories } from './categories.entity'; // Import Categories entity

describe("CategoriesService", () => {
  let service: CategoriesService;

  const mockPhotoRepository = {
    // Mock methods used by CategoriesService on Photo entity
    create: jest.fn(),
    destroy: jest.fn(),
    // Add other methods as needed
  };

  const mockPostsRepository = {
    // Mock methods used by CategoriesService on Posts entity
    findOne: jest.fn(),
    findAll: jest.fn(),
    // Add other methods as needed
  };

  const mockCategoriesRepository = {
    // Mock methods used by CategoriesService on Categories entity
    create: jest.fn(),
    findOne: jest.fn(),
    findAll: jest.fn(),
    destroy: jest.fn(),
    // Add other methods as needed
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CategoriesService,
        {
          provide: "PHOTO_REPOSITORY",
          useValue: mockPhotoRepository,
        },
        {
          provide: "POSTS_REPOSITORY",
          useValue: mockPostsRepository,
        },
        {
          provide: "CATEGORIES_REPOSITORY",
          useValue: mockCategoriesRepository,
        },
      ],
    }).compile();

    service = module.get<CategoriesService>(CategoriesService);
  });

  it("should be defined", () => {
    expect(service).toBeDefined();
  });
});
