import { Test, TestingModule } from "@nestjs/testing";
import { FileController } from "./file.controller";
import { FileService } from "./file.service"; // Import FileService

describe("FileController", () => {
  let controller: FileController;

  const mockFileService = {
    // Mock methods used by FileController on FileService
    createFile: jest.fn(),
    getFileById: jest.fn(),
    deleteFile: jest.fn(),
    // Add other methods as needed
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [FileController],
      providers: [
        {
          provide: FileService,
          useValue: mockFileService,
        },
      ],
    }).compile();

    controller = module.get<FileController>(FileController);
  });

  it("should be defined", () => {
    expect(controller).toBeDefined();
  });
});
