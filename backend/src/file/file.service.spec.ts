import { Test, TestingModule } from "@nestjs/testing";
import { FileService } from "./file.service";
import { File } from "./file.entity"; // Import File entity

describe("FileService", () => {
  let service: FileService;
  const mockFileRepository = {
    findAll: jest.fn(),
    // Add any other methods that FileService calls on the File repository
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        FileService,
        {
          provide: "FILE_REPOSITORY", // This token should match the injection token in FileService
          useValue: mockFileRepository,
        },
      ],
    }).compile();

    service = module.get<FileService>(FileService);
  });

  it("should be defined", () => {
    expect(service).toBeDefined();
  });
});
