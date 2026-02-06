import { Body, Controller, HttpStatus, Post, Req, Res } from "@nestjs/common";
import { ApiBody, ApiResponse, ApiTags } from "@nestjs/swagger";
import { Throttle } from "@nestjs/throttler";
import { Request, Response } from "express";
import { OtpService } from "./otp.service";
import { GetTime, SendOtp } from "./get-time.dto";

@Controller({
  path: "otp",
  version: "1",
})
@ApiTags("OTP Authentication")
export class OtpController {
  constructor(private readonly otpService: OtpService) {}

  // Strict rate limit: 3 requests per 60 seconds per IP
  @Throttle({ default: { ttl: 60000, limit: 3 } })
  @Post("send")
  @ApiBody({ type: SendOtp })
  @ApiResponse({
    status: HttpStatus.OK,
    description: "OTP sent successfully",
    schema: {
      example: {
        message: "OTP sent successfully",
        requestId: "uuid",
        phone: "+99362120020",
        expiresAt: "2026-02-02T12:00:00.000Z",
      },
    },
  })
  @ApiResponse({
    status: HttpStatus.BAD_REQUEST,
    description: "Invalid phone number",
    schema: { example: { code: "OTP_INVALID_PHONE", message: "Phone number is required" } },
  })
  @ApiResponse({
    status: HttpStatus.TOO_MANY_REQUESTS,
    description: "Rate limit exceeded",
    schema: { example: { code: "OTP_RATE_LIMIT", message: "Too many OTP requests" } },
  })
  async sendOtp(
    @Body() body: SendOtp,
    @Req() req: Request,
    @Res() res: Response,
  ): Promise<any> {
    const phone = body?.phone;
    if (!phone) {
      return res
        .status(HttpStatus.BAD_REQUEST)
        .json({ message: "Phone number is required" });
    }
    return this.otpService.sendOtp({ phone } as SendOtp, res, req);
  }

  // Strict rate limit: 5 requests per 60 seconds per IP
  @Throttle({ default: { ttl: 60000, limit: 5 } })
  @Post("verify")
  @ApiBody({ type: GetTime })
  @ApiResponse({
    status: HttpStatus.OK,
    description: "OTP verified, tokens returned",
    schema: {
      example: {
        message: "Login successful",
        accessToken: "jwt-access-token",
        refreshToken: "jwt-refresh-token",
      },
    },
  })
  @ApiResponse({
    status: HttpStatus.UNAUTHORIZED,
    description: "Invalid OTP",
    schema: {
      example: {
        code: "OTP_INVALID",
        message: "Incorrect OTP. 4 attempts remaining.",
      },
    },
  })
  async verifyOtp(
    @Body() body: GetTime,
    @Res() res: Response,
  ): Promise<any> {
    return this.otpService.checkOtp(body, res);
  }
}
