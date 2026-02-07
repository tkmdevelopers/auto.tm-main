import { Test, TestingModule } from "@nestjs/testing";
import { VideoController } from "./video.controller";
import { VideoService } from "./video.service"; // Import VideoService

describe("VideoController", () => {
  let controller: VideoController;

  const mockVideoService = {
    // Mock methods used by VideoController on VideoService
    createVideo: jest.fn(),
    getVideoById: jest.fn(),
    deleteVideo: jest.fn(),
    // Add other methods as needed
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [VideoController],
      providers: [
        {
          provide: VideoService,
          useValue: mockVideoService,
        },
      ],
    }).compile();

    controller = module.get<VideoController>(VideoController);
  });

  it("should be defined", () => {
    expect(controller).toBeDefined();
  });
});
