import { Test, TestingModule } from "@nestjs/testing";
import { BrandsService } from "./brands.service";
import { Brands } from "./brands.entity"; // Import Brands entity
import { Models } from "../models/models.entity"; // Import Models entity
import { Posts } from "../post/post.entity"; // Import Posts entity
import { User } from "../auth/auth.entity"; // Import User entity
import { Photo } from "../photo/photo.entity"; // Import Photo entity

describe("BrandsService", () => {
  let service: BrandsService;

  const mockBrandsRepository = {
    // Mock methods used by BrandsService on Brands entity
    create: jest.fn(),
    findOne: jest.fn(),
    findAll: jest.fn(),
    update: jest.fn(),
    deleteOne: jest.fn(),
    // Add other methods as needed
  };

  const mockModelsRepository = {
    // Mock methods used by BrandsService on Models entity
    findOne: jest.fn(),
    // Add other methods as needed
  };

  const mockPostsRepository = {
    // Mock methods used by BrandsService on Posts entity
    findOne: jest.fn(),
    // Add other methods as needed
  };

  const mockUserRepository = {
    // Mock methods used by BrandsService on User entity
    findOne: jest.fn(),
    // Add other methods as needed
  };

  const mockPhotoRepository = {
    // Mock methods used by BrandsService on Photo entity
    create: jest.fn(),
    destroy: jest.fn(),
    // Add other methods as needed
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        BrandsService,
        {
          provide: "BRANDS_REPOSITORY",
          useValue: mockBrandsRepository,
        },
        {
          provide: "MODELS_REPOSITORY",
          useValue: mockModelsRepository,
        },
        {
          provide: "POSTS_REPOSITORY",
          useValue: mockPostsRepository,
        },
        {
          provide: "USERS_REPOSITORY",
          useValue: mockUserRepository,
        },
        {
          provide: "PHOTO_REPOSITORY",
          useValue: mockPhotoRepository,
        },
      ],
    }).compile();

    service = module.get<BrandsService>(BrandsService);
  });

  it("should be defined", () => {
    expect(service).toBeDefined();
  });
});
