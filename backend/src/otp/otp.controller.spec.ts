import { Test, TestingModule } from "@nestjs/testing";
import { OtpController } from "./otp.controller";
import { OtpService } from "./otp.service"; // Import OtpService

describe("OtpController", () => {
  let controller: OtpController;

  const mockOtpService = {
    // Mock methods used by OtpController on OtpService
    sendOtp: jest.fn(),
    verifyOtp: jest.fn(),
    // Add other methods as needed
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [OtpController],
      providers: [
        {
          provide: OtpService,
          useValue: mockOtpService,
        },
      ],
    }).compile();

    controller = module.get<OtpController>(OtpController);
  });

  it("should be defined", () => {
    expect(controller).toBeDefined();
  });
});
