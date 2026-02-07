import { Test, TestingModule } from "@nestjs/testing";
import { PhotoService } from "./photo.service";
import { Photo } from './photo.entity'; // Import Photo entity

describe("PhotoService", () => {
  let service: PhotoService;

  const mockPhotoRepository = {
    // Mock methods used by PhotoService on Photo entity
    create: jest.fn(),
    findOne: jest.fn(),
    destroy: jest.fn(),
    // Add other methods as needed
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PhotoService,
        {
          provide: "PHOTO_REPOSITORY", // This token should match the injection token in PhotoService
          useValue: mockPhotoRepository,
        },
      ],
    }).compile();

    service = module.get<PhotoService>(PhotoService);
  });

  it("should be defined", () => {
    expect(service).toBeDefined();
  });
});
