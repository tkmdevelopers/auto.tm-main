import { Controller, Get, HttpStatus, Query, Req, Res } from "@nestjs/common";
import { ApiQuery, ApiResponse, ApiTags } from "@nestjs/swagger";
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
    schema: {
      example: {
        message: "Phone number is required",
      },
    },
  })
  @ApiQuery({ name: "phone", required: true, description: "Phone number" })
  @Get("send")
  async sendOtp(
    @Query("phone") phone: string,
    @Req() req: Request,
    @Res() res: Response,
  ): Promise<any> {
    if (!phone) {
      return res
        .status(HttpStatus.BAD_REQUEST)
        .json({ message: "Invalid Phone Number" });
    }
    return this.otpService.sendOtp({ phone } as SendOtp, res, req);
  }

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
        message: "Incorrect OTP. 4 attempts remaining.",
      },
    },
  })
  @Get("verify")
  async verifyOtp(@Query() query: GetTime, @Res() res: Response): Promise<any> {
    return this.otpService.checkOtp(query, res);
  }

  @ApiResponse({
    status: HttpStatus.OK,
    description: "OTP sent for verification",
    schema: {
      example: {
        message: "OTP sent successfully",
        requestId: "uuid",
        phone: "+99362120020",
        expiresAt: "2026-02-02T12:00:00.000Z",
      },
    },
  })
  @Get("sendVerification")
  async sendVerification(
    @Query("phone") phone: string,
    @Req() req: Request,
    @Res() res: Response,
  ): Promise<any> {
    if (!phone) {
      return res
        .status(HttpStatus.BAD_REQUEST)
        .json({ message: "Invalid Phone Number" });
    }
    return this.otpService.sendOtp({ phone } as SendOtp, res, req);
  }

  @ApiResponse({
    status: HttpStatus.OK,
    description: "Phone verification successful",
    schema: {
      example: {
        message: "Verification successful",
        response: true,
        userId: "uuid",
      },
    },
  })
  @ApiResponse({
    status: HttpStatus.NOT_ACCEPTABLE,
    description: "Invalid verification code",
    schema: {
      example: {
        message: "Incorrect OTP. 4 attempts remaining.",
        response: false,
      },
    },
  })
  @Get("verifyVerification")
  async verifyVerification(
    @Query() query: GetTime,
    @Res() res: Response,
  ): Promise<any> {
    return this.otpService.checkVerification(query, res);
  }
}
