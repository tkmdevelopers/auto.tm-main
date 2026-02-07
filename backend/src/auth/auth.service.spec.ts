import { Test, TestingModule } from "@nestjs/testing";
import { AuthService } from "./auth.service";
import { User } from './auth.entity'; // Import User entity
import { Photo } from '../photo/photo.entity'; // Import Photo entity
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';

describe("AuthService", () => {
  let service: AuthService;

  const mockUserRepository = {
    // Mock methods used by AuthService on User entity
    findOne: jest.fn(),
    create: jest.fn(),
    // Add other methods as needed
  };

  const mockPhotoRepository = {
    // Mock methods used by AuthService on Photo entity
    create: jest.fn(),
    destroy: jest.fn(),
    // Add other methods as needed
  };

  const mockConfigService = {
    get: jest.fn((key: string) => {
      if (key === 'JWT_SECRET') return 'test_jwt_secret';
      if (key === 'JWT_REFRESH_SECRET') return 'test_jwt_refresh_secret';
      return null;
    }),
  };

  const mockJwtService = {
    sign: jest.fn(() => 'mock_jwt_token'),
    signAsync: jest.fn(() => 'mock_jwt_token_async'),
    // Add other methods used by AuthService on JwtService
  };


  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuthService,
        {
          provide: "USERS_REPOSITORY",
          useValue: mockUserRepository,
        },
        {
          provide: "PHOTO_REPOSITORY",
          useValue: mockPhotoRepository,
        },
        {
          provide: ConfigService,
          useValue: mockConfigService,
        },
        {
          provide: JwtService,
          useValue: mockJwtService,
        },
      ],
    }).compile();

    service = module.get<AuthService>(AuthService);
  });

  it("should be defined", () => {
    expect(service).toBeDefined();
  });
});
