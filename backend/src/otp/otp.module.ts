import { Module, forwardRef } from "@nestjs/common";
import { OtpController } from "./otp.controller";
import { OtpService } from "./otp.service";
import { UtilProviders } from "src/utils/utilsProvider";
import { PassportModule } from "@nestjs/passport";
import { JwtModule } from "@nestjs/jwt";
import { SmsModule } from "src/sms/sms.module";

@Module({
  imports: [
    PassportModule.register({ defaultStrategy: "jwt" }),
    JwtModule.register({}),
    forwardRef(() => SmsModule), // For SMS dispatch
  ],
  controllers: [OtpController],
  providers: [OtpService, ...UtilProviders],
  exports: [OtpService], // Export for use in other modules
})
export class OtpModule {}
