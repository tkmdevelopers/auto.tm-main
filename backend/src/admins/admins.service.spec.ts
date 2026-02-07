import { Test, TestingModule } from "@nestjs/testing";
import { AdminsService } from "./admins.service";
import { User } from "../auth/auth.entity"; // Import User entity

describe("AdminsService", () => {
  let service: AdminsService;
  const mockUserRepository = {
    findAll: jest.fn(),
    // Add any other methods that AdminsService calls on the User repository
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AdminsService,
        {
          provide: "USERS_REPOSITORY", // This token should match the injection token in AdminsService
          useValue: mockUserRepository,
        },
      ],
    }).compile();

    service = module.get<AdminsService>(AdminsService);
  });

  it("should be defined", () => {
    expect(service).toBeDefined();
  });
});
