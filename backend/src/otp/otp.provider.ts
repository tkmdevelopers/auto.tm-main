import { OtpCode } from "./otp-codes.entity";

export const OtpCodeProvider = [
  {
    provide: "OTP_CODE_REPOSITORY",
    useValue: OtpCode,
  },
];

// Legacy export for backward compatibility during migration
export const OtpTempProvider = OtpCodeProvider;
