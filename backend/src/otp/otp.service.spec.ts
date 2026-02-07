import { Test, TestingModule } from "@nestjs/testing";
import { OtpService, OtpConfig } from "./otp.service";
import { JwtService } from "@nestjs/jwt";
import { ConfigService } from "@nestjs/config";
import { OtpPurpose } from "./otp-codes.entity";
import * as bcrypt from 'bcryptjs';

// Mock dependencies
const mockUserRepository = {
  findOne: jest.fn(),
  create: jest.fn(),
  update: jest.fn(),
};

const mockOtpCodeRepository = {
  create: jest.fn(),
  findOne: jest.fn(),
  update: jest.fn(),
  count: jest.fn(),
  destroy: jest.fn(),
  increment: jest.fn(),
};

const mockJwtService = {
  signAsync: jest.fn().mockResolvedValue('mock_token'),
};

const mockConfigService = {
  get: jest.fn((key: string) => {
    if (key === 'OTP_TTL_SECONDS') return '300';
    if (key === 'OTP_MAX_ATTEMPTS') return '5';
    if (key === 'OTP_TEST_MODE') return 'true';
    if (key === 'TEST_OTP_NUMBERS') return '99361999999';
    return null;
  }),
};

// Mock SMS Service (Optional)
const mockSmsService = {
  sendOtpSms: jest.fn().mockResolvedValue({ sent: true, correlationId: '123' }),
};

describe("OtpService", () => {
  let service: OtpService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        OtpService,
        { provide: "USERS_REPOSITORY", useValue: mockUserRepository },
        { provide: "OTP_CODE_REPOSITORY", useValue: mockOtpCodeRepository },
        { provide: JwtService, useValue: mockJwtService },
        { provide: ConfigService, useValue: mockConfigService },
        { provide: "SmsService", useValue: mockSmsService }, // If injected by token, otherwise class
      ],
    }).compile();

    service = module.get<OtpService>(OtpService);
    jest.clearAllMocks();
  });

  it("should be defined", () => {
    expect(service).toBeDefined();
  });

  describe("createOtp", () => {
    it("should create a deterministic OTP for test numbers", async () => {
      const params = {
        phone: "+99361999999", // Test number
        purpose: OtpPurpose.LOGIN,
      };

      mockOtpCodeRepository.create.mockResolvedValue({ id: 'test-id' });

      const result = await service.createOtp(params);

      expect(result.code).toBe("12345");
      expect(result.isTestNumber).toBe(true);
      expect(mockOtpCodeRepository.create).toHaveBeenCalled();
    });

    it("should create a random OTP for real numbers and hash it", async () => {
      const params = {
        phone: "+99365000000",
        purpose: OtpPurpose.LOGIN,
      };

      mockOtpCodeRepository.create.mockImplementation((data) => {
          return { ...data, id: 'real-id' };
      });
      mockOtpCodeRepository.count.mockResolvedValue(0); // Rate limit check

      const result = await service.createOtp(params);

      expect(result.code).not.toBe("12345");
      expect(result.isTestNumber).toBe(false);
      // Verify hash was created (we can't check the value easily, but we check logic flow)
      const createCall = mockOtpCodeRepository.create.mock.calls[0][0];
      expect(createCall.codeHash).toBeDefined();
      expect(createCall.codeHash).not.toBe(result.code); 
    });
  });

  describe("verifyOtp", () => {
    it("should verify a valid OTP", async () => {
      const phone = "+99361999999";
      const code = "12345";
      const hash = await bcrypt.hash(code, 10);

      // Mock OTP record found in DB
      mockOtpCodeRepository.findOne.mockResolvedValue({
        id: 'otp-id',
        codeHash: hash,
        attempts: 0,
        maxAttempts: 5,
        expiresAt: new Date(Date.now() + 10000), // Future
        increment: jest.fn(),
        update: jest.fn(),
      });

      mockUserRepository.findOne.mockResolvedValue({ uuid: 'user-id', status: true });

      const result = await service.verifyOtp({ phone, code, purpose: OtpPurpose.LOGIN });

      expect(result.valid).toBe(true);
      expect(result.message).toContain("verified successfully");
    });

    it("should reject an invalid OTP", async () => {
        const phone = "+99361999999";
        const code = "12345";
        const wrongCode = "00000";
        const hash = await bcrypt.hash(code, 10);
  
        // Mock OTP record found in DB
        mockOtpCodeRepository.findOne.mockResolvedValue({
          id: 'otp-id',
          codeHash: hash,
          attempts: 0,
          maxAttempts: 5,
          expiresAt: new Date(Date.now() + 10000),
          increment: jest.fn(),
          update: jest.fn(),
        });
  
        const result = await service.verifyOtp({ phone, code: wrongCode, purpose: OtpPurpose.LOGIN });
  
        expect(result.valid).toBe(false);
        expect(result.code).toBe("OTP_INVALID");
      });
  });
});
