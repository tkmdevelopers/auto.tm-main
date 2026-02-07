import { Test, TestingModule } from "@nestjs/testing";
import { VlogService } from "./vlog.service";
import { Vlogs } from './vlog.entity'; // Import Vlogs entity

describe("VlogService", () => {
  let service: VlogService;
  const mockVlogRepository = {
    findAll: jest.fn(),
    // Add any other methods that VlogService calls on the Vlog repository
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        VlogService,
        {
          provide: "VLOG_REPOSITORY", // This token should match the injection token in VlogService
          useValue: mockVlogRepository,
        },
      ],
    }).compile();

    service = module.get<VlogService>(VlogService);
  });

  it("should be defined", () => {
    expect(service).toBeDefined();
  });
});
