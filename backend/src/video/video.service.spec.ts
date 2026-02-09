import { Test, TestingModule } from "@nestjs/testing";
import { VideoService } from "./video.service";
import { Posts } from "../post/post.entity"; // Import Posts entity
import { Video } from "./video.entity"; // Import Video entity

describe("VideoService", () => {
  let service: VideoService;

  const mockPostsRepository = {
    // Mock methods used by VideoService on Posts entity
    findOne: jest.fn(),
    // Add other methods as needed
  };

  const mockVideoRepository = {
    // Mock methods used by VideoService on Video entity
    create: jest.fn(),
    findOne: jest.fn(),
    destroy: jest.fn(),
    // Add other methods as needed
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        VideoService,
        {
          provide: "POSTS_REPOSITORY", // This token should match the injection token in VideoService
          useValue: mockPostsRepository,
        },
        {
          provide: "VIDEO_REPOSITORY", // This token should match the injection token in VideoService
          useValue: mockVideoRepository,
        },
      ],
    }).compile();

    service = module.get<VideoService>(VideoService);
  });

  it("should be defined", () => {
    expect(service).toBeDefined();
  });
});
