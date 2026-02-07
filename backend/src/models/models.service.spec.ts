import { Test, TestingModule } from "@nestjs/testing";
import { ModelsService } from "./models.service";
import { Brands } from '../brands/brands.entity'; // Import Brands entity
import { Models } from './models.entity'; // Import Models entity
import { Posts } from '../post/post.entity'; // Import Posts entity
import { Photo } from '../photo/photo.entity'; // Import Photo entity

describe("ModelsService", () => {
  let service: ModelsService;

  const mockBrandsRepository = {
    // Mock methods used by ModelsService on Brands entity
    findOne: jest.fn(),
    // Add other methods as needed
  };

  const mockModelsRepository = {
    // Mock methods used by ModelsService on Models entity
    create: jest.fn(),
    findOne: jest.fn(),
    findAll: jest.fn(),
    destroy: jest.fn(),
    // Add other methods as needed
  };

  const mockPostsRepository = {
    // Mock methods used by ModelsService on Posts entity
    findOne: jest.fn(),
    // Add other methods as needed
  };

  const mockPhotoRepository = {
    // Mock methods used by ModelsService on Photo entity
    create: jest.fn(),
    destroy: jest.fn(),
    // Add other methods as needed
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ModelsService,
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
          provide: "PHOTO_REPOSITORY",
          useValue: mockPhotoRepository,
        },
      ],
    }).compile();

    service = module.get<ModelsService>(ModelsService);
  });

  it("should be defined", () => {
    expect(service).toBeDefined();
  });
});
