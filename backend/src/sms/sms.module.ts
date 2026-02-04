import { Module } from "@nestjs/common";
import { ConfigModule } from "@nestjs/config";
import { EventEmitterModule } from "@nestjs/event-emitter";
import { SmsGateway } from "./sms.gateway";
import { SmsService } from "./sms.service";
import { smsConfig } from "./sms.config";
import { OtpCodeProvider } from "src/otp/otp.provider";

/**
 * SMS Module
 *
 * Provides SMS functionality via connected physical devices.
 *
 * Architecture:
 * - SmsGateway: Socket.IO server on port 3091, accepts device connections
 * - SmsService: High-level API for sending SMS (OTP or custom messages)
 *
 * The physical SMS device (mobile phone) connects to the gateway
 * and receives SMS requests. After sending, it acknowledges back.
 */
@Module({
  imports: [ConfigModule.forFeature(smsConfig), EventEmitterModule.forRoot()],
  providers: [
    SmsGateway,
    SmsService,
    ...OtpCodeProvider, // For updating OTP dispatch status
  ],
  exports: [SmsService, SmsGateway],
})
export class SmsModule {}
