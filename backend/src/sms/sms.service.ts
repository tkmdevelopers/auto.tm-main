import { Injectable, Logger, OnModuleInit } from "@nestjs/common";
import { v4 as uuidv4 } from "uuid";
import { SmsGateway, SmsAck } from "./sms.gateway";
import { OtpDispatchStatus } from "src/otp/otp-codes.entity";
import { EventEmitter2, OnEvent } from "@nestjs/event-emitter";
import { Inject, forwardRef } from "@nestjs/common";
import { OtpCode } from "src/otp/otp-codes.entity";

/**
 * SMS Service
 *
 * High-level service for sending SMS messages via connected physical devices.
 *
 * Architecture:
 * - Physical phone connects to SmsGateway (port 3091)
 * - This service sends OTP requests to the gateway
 * - Gateway routes to the appropriate connected device
 * - Device sends SMS and acknowledges
 * - This service updates OTP dispatch status
 */
@Injectable()
export class SmsService implements OnModuleInit {
  private readonly logger = new Logger(SmsService.name);

  // OTP message template
  private otpTemplate: string;
  private otpTtlMinutes: number;

  constructor(
    private readonly smsGateway: SmsGateway,
    private readonly eventEmitter: EventEmitter2,
    @Inject("OTP_CODE_REPOSITORY") private otpCodeRepository: typeof OtpCode,
  ) {
    this.otpTemplate =
      process.env.SMS_OTP_TEMPLATE ||
      "Alpha Motors: Your verification code is {code}. Valid for {ttl} minutes.";
    this.otpTtlMinutes = Math.round(
      parseInt(process.env.OTP_TTL_SECONDS || "300", 10) / 60,
    );
  }

  async onModuleInit() {
    this.logger.log("SMS Service initialized");
    this.logger.log(`OTP Template: ${this.otpTemplate}`);
  }

  /**
   * Handle SMS acknowledgment events from gateway
   */
  @OnEvent("sms.ack")
  async handleSmsAck(ack: SmsAck & { otpRequestId?: string }): Promise<void> {
    this.logger.log("Processing SMS ack", {
      correlationId: ack.correlationId,
      status: ack.status,
      otpRequestId: ack.otpRequestId,
    });

    // Update OTP dispatch status if we have the request ID
    if (ack.otpRequestId) {
      const dispatchStatus =
        ack.status === "sent" || ack.status === "delivered"
          ? OtpDispatchStatus.SENT
          : OtpDispatchStatus.FAILED;

      await this.otpCodeRepository.update(
        { dispatchStatus },
        { where: { id: ack.otpRequestId } },
      );

      this.logger.log(
        `OTP dispatch status updated: ${ack.otpRequestId} -> ${dispatchStatus}`,
      );
    }
  }

  /**
   * Format OTP message from template
   */
  formatOtpMessage(code: string): string {
    return this.otpTemplate
      .replace("{code}", code)
      .replace("{ttl}", String(this.otpTtlMinutes));
  }

  /**
   * Send OTP via SMS
   *
   * @param phone - Phone number in E.164 format
   * @param code - OTP code to send
   * @param requestId - OTP request ID for status tracking
   * @param region - Region for SMS routing (optional)
   */
  async sendOtpSms(params: {
    phone: string;
    code: string;
    requestId: string;
    region?: string;
  }): Promise<{ sent: boolean; correlationId: string }> {
    const correlationId = uuidv4();
    const text = this.formatOtpMessage(params.code);

    // Update OTP status to pending
    await this.otpCodeRepository.update(
      { dispatchStatus: OtpDispatchStatus.PENDING },
      { where: { id: params.requestId } },
    );

    // Send via gateway
    const sent = await this.smsGateway.sendSms({
      correlationId,
      phone: params.phone,
      text,
      region: params.region,
      otpRequestId: params.requestId,
    });

    if (!sent) {
      // No device available, mark as failed
      await this.otpCodeRepository.update(
        { dispatchStatus: OtpDispatchStatus.FAILED },
        { where: { id: params.requestId } },
      );
    }

    return { sent, correlationId };
  }

  /**
   * Check if SMS gateway has any connected devices
   */
  isDeviceAvailable(region?: string): boolean {
    return this.smsGateway.hasConnectedDevice(region);
  }

  /**
   * Get list of connected SMS devices
   */
  getConnectedDevices() {
    return this.smsGateway.getConnectedDevices();
  }

  /**
   * Send a custom SMS (non-OTP)
   */
  async sendSms(params: {
    phone: string;
    text: string;
    region?: string;
  }): Promise<{ sent: boolean; correlationId: string }> {
    const correlationId = uuidv4();

    const sent = await this.smsGateway.sendSms({
      correlationId,
      phone: params.phone,
      text: params.text,
      region: params.region,
    });

    return { sent, correlationId };
  }
}
