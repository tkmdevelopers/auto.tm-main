import { Test, TestingModule } from "@nestjs/testing";
import { BannersService } from "./banners.service";
import { Photo } from '../photo/photo.entity'; // Import Photo entity
import { Banners } from './banners.entity'; // Import Banners entity

describe("BannersService", () => {
  let service: BannersService;

  const mockPhotoRepository = {
    // Mock methods used by BannersService on Photo entity
    create: jest.fn(),
    destroy: jest.fn(),
    // Add other methods as needed
  };

  const mockBannersRepository = {
    // Mock methods used by BannersService on Banners entity
    create: jest.fn(),
    findOne: jest.fn(),
    findAll: jest.fn(),
    destroy: jest.fn(),
    // Add other methods as needed
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        BannersService,
        {
          provide: "PHOTO_REPOSITORY",
          useValue: mockPhotoRepository,
        },
        {
          provide: "BANNERS_REPOSITORY",
          useValue: mockBannersRepository,
        },
      ],
    }).compile();

    service = module.get<BannersService>(BannersService);
  });

  it("should be defined", () => {
    expect(service).toBeDefined();
  });
});
