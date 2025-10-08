import { OtpTemp } from './otp.entity';

export const OtpTempProvider = [
  {
    provide: 'OTP_TEMP_REPOSITORY',
    useValue: OtpTemp,
  },
];
