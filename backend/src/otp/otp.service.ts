import {
  HttpException,
  HttpStatus,
  Inject,
  Injectable,
  Optional,
} from "@nestjs/common";
import { JwtService } from "@nestjs/jwt";
import { ConfigService } from "@nestjs/config";
import { User } from "src/auth/auth.entity";
import { OtpCode, OtpPurpose, OtpDispatchStatus } from "./otp-codes.entity";
import { v4 as uuidv4 } from "uuid";
import * as bcrypt from "bcryptjs";
import { Op } from "sequelize";
import { SmsService } from "src/sms/sms.service";
import { hashToken } from "src/utils/token.utils";

/**
 * Configuration for OTP generation and validation
 */
export interface OtpConfig {
  /** OTP length (default: 5) */
  length: number;
  /** OTP TTL in seconds (default: 300 = 5 minutes) */
  ttlSeconds: number;
  /** Maximum verification attempts (default: 5) */
  maxAttempts: number;
  /** Bcrypt salt rounds for hashing (default: 10) */
  saltRounds: number;
}

/**
 * Parameters for creating an OTP
 */
export interface CreateOtpParams {
  phone: string;
  purpose: OtpPurpose;
  region?: string;
  ipAddress?: string;
  userAgent?: string;
}

/**
 * Result of OTP creation
 */
export interface CreateOtpResult {
  /** Request ID for tracking */
  requestId: string;
  /** Phone number (normalized) */
  phone: string;
  /** Purpose of the OTP */
  purpose: OtpPurpose;
  /** Expiration timestamp */
  expiresAt: Date;
  /** The actual OTP code (only returned for dispatch, never logged) */
  code: string;
  /** Whether this is a test number */
  isTestNumber: boolean;
  /** Whether SMS was dispatched automatically */
  smsDispatched?: boolean;
}

/**
 * Parameters for verifying an OTP
 */
export interface VerifyOtpParams {
  phone: string;
  purpose: OtpPurpose;
  code: string;
}

/**
 * Result of OTP verification
 */
export interface VerifyOtpResult {
  valid: boolean;
  userId?: string;
  message: string;
  requestId?: string;
  code?: string;
}

/**
 * Unified OTP Service
 *
 * Features:
 * - Centralized OTP creation with hashing (never stores plaintext)
 * - TTL enforcement
 * - Attempt tracking and brute-force protection
 * - Test number support (deterministic OTP for testing)
 * - Reusable across modules (auth, profile, etc.)
 */
@Injectable()
export class OtpService {
  private readonly config: OtpConfig;
  private readonly testNumbers: Set<string>;
  private readonly testNumbersProd: Set<string>;
  private readonly testOtpPrefix: string;
  private readonly phoneRateLimitWindowMs: number;
  private readonly phoneRateLimitMax: number;
  private readonly testModeEnabled: boolean;
  private readonly allowTestInProd: boolean;
  private readonly isProd: boolean;
  private readonly exposeTestCode: boolean;

  constructor(
    @Inject("USERS_REPOSITORY") private userRepository: typeof User,
    @Inject("OTP_CODE_REPOSITORY") private otpCodeRepository: typeof OtpCode,
    private jwtService: JwtService,
    private configService: ConfigService,
    @Optional() private smsService?: SmsService,
  ) {
    // Initialize configuration
    this.config = {
      length: 5,
      ttlSeconds: parseInt(
        this.configService.get("OTP_TTL_SECONDS") || "300",
        10,
      ),
      maxAttempts: parseInt(
        this.configService.get("OTP_MAX_ATTEMPTS") || "5",
        10,
      ),
      saltRounds: 10,
    };

    this.phoneRateLimitWindowMs = parseInt(
      this.configService.get("OTP_PHONE_RATE_LIMIT_WINDOW_MS") || "60000",
      10,
    );
    this.phoneRateLimitMax = parseInt(
      this.configService.get("OTP_PHONE_RATE_LIMIT_MAX") || "3",
      10,
    );

    this.isProd =
      (this.configService.get("NODE_ENV") || "").toLowerCase() ===
      "production";
    this.testModeEnabled =
      (this.configService.get("OTP_TEST_MODE") || "false").toLowerCase() ===
      "true";
    this.allowTestInProd =
      (this.configService.get("OTP_TEST_ALLOW_IN_PROD") || "false")
        .toLowerCase() === "true";
    this.exposeTestCode =
      (this.configService.get("OTP_TEST_CODE_RESPONSE") || "false")
        .toLowerCase() === "true";

    // Initialize test numbers from environment
    const envListRaw = this.configService.get("TEST_OTP_NUMBERS") || "";
    const envListProdRaw =
      this.configService.get("TEST_OTP_NUMBERS_PROD") || "";
    this.testOtpPrefix =
      this.configService.get("TEST_OTP_PREFIX") || "9936199999";

    this.testNumbers = new Set<string>([
      // Hardcoded test numbers
      "99361999999",
      "99361999991",
      "99361999992",
      "99361999993",
      // From environment
      ...envListRaw
        .split(",")
        .map((s) => s.trim())
        .filter(Boolean),
    ]);

    this.testNumbersProd = new Set<string>([
      ...envListProdRaw
        .split(",")
        .map((s) => s.trim())
        .filter(Boolean),
    ]);
  }

  /**
   * Normalize phone number to E.164 format
   */
  private normalizePhone(phone: string): string {
    if (!phone) return phone;
    // Remove all non-digit characters except leading +
    let normalized = phone.replace(/[^\d+]/g, "");
    // Ensure leading +
    if (!normalized.startsWith("+")) {
      normalized = `+${normalized}`;
    }
    return normalized;
  }

  /**
   * Extract digits from phone number for comparison
   */
  private getDigits(phone: string): string {
    return (phone || "").replace(/\D/g, "");
  }

  /**
   * Check if a phone number is a test number
   */
  private isTestNumber(phone: string): boolean {
    const digits = this.getDigits(phone);
    if (!this.testModeEnabled) return false;
    if (this.isProd && !this.allowTestInProd) return false;

    if (this.isProd && this.allowTestInProd) {
      if (this.testNumbersProd.size > 0) {
        return this.testNumbersProd.has(digits);
      }
      return this.testNumbers.has(digits) ||
          digits.startsWith(this.testOtpPrefix);
    }

    return this.testNumbers.has(digits) || digits.startsWith(this.testOtpPrefix);
  }

  /**
   * Generate a random OTP code
   */
  private generateOtp(): string {
    const min = Math.pow(10, this.config.length - 1);
    const max = Math.pow(10, this.config.length) - 1;
    return String(Math.floor(Math.random() * (max - min + 1)) + min);
  }

  /**
   * Hash an OTP code using bcrypt
   */
  private async hashOtp(code: string): Promise<string> {
    return bcrypt.hash(code, this.config.saltRounds);
  }

  /**
   * Verify an OTP code against its hash
   */
  private async verifyOtpHash(code: string, hash: string): Promise<boolean> {
    return bcrypt.compare(code, hash);
  }

  /**
   * Create and store a new OTP
   *
   * @param params - OTP creation parameters
   * @returns OTP creation result with the code for dispatch
   */
  async createOtp(params: CreateOtpParams): Promise<CreateOtpResult> {
    const { purpose, region, ipAddress, userAgent } = params;
    const phone = this.normalizePhone(params.phone);

    if (!phone) {
      throw new HttpException(
        {
          code: "OTP_INVALID_PHONE",
          message: "Phone number is required",
        },
        HttpStatus.BAD_REQUEST,
      );
    }

    // Check if this is a test number
    const isTestNumber = this.isTestNumber(phone);

    // Per-phone rate limit (independent of IP throttling)
    if (!isTestNumber) {
      const windowStart = new Date(
        Date.now() - this.phoneRateLimitWindowMs,
      );
      const recentCount = await this.otpCodeRepository.count({
        where: {
          phone,
          purpose,
          createdAt: { [Op.gte]: windowStart },
        },
      });
      if (recentCount >= this.phoneRateLimitMax) {
        throw new HttpException(
          {
            code: "OTP_RATE_LIMIT",
            message: "Too many OTP requests for this phone. Please wait.",
          },
          HttpStatus.TOO_MANY_REQUESTS,
        );
      }
    }

    // Generate OTP (deterministic for test numbers)
    const code = isTestNumber ? "12345" : this.generateOtp();

    // Hash the OTP for storage
    const codeHash = await this.hashOtp(code);

    // Calculate expiration
    const expiresAt = new Date(Date.now() + this.config.ttlSeconds * 1000);

    // Invalidate any existing unused OTPs for this phone + purpose
    await this.otpCodeRepository.update(
      { consumedAt: new Date() },
      {
        where: {
          phone,
          purpose,
          consumedAt: null,
          expiresAt: { [Op.gt]: new Date() },
        },
      },
    );

    // Create new OTP record
    const otpRecord = await this.otpCodeRepository.create({
      id: uuidv4(),
      phone,
      purpose,
      codeHash,
      expiresAt,
      maxAttempts: this.config.maxAttempts,
      region: region || null,
      ipAddress: ipAddress || null,
      userAgent: userAgent || null,
      dispatchStatus: OtpDispatchStatus.PENDING,
    } as any);

    // Log OTP creation (without the code itself)
    console.log("[OtpService] OTP created", {
      requestId: otpRecord.id,
      phone,
      purpose,
      expiresAt,
      isTestNumber,
    });

    // Auto-dispatch via SMS if service is available and not a test number
    let smsDispatched = false;
    if (this.smsService && !isTestNumber) {
      try {
        const result = await this.smsService.sendOtpSms({
          phone,
          code,
          requestId: otpRecord.id,
          region,
        });
        smsDispatched = result.sent;
        console.log("[OtpService] SMS dispatch", {
          requestId: otpRecord.id,
          sent: result.sent,
          correlationId: result.correlationId,
        });
      } catch (error) {
        console.error("[OtpService] SMS dispatch failed:", error);
        // Continue - OTP is still valid, just not sent via SMS
      }
    }

    return {
      requestId: otpRecord.id,
      phone,
      purpose,
      expiresAt,
      code, // Return for dispatch (caller must send via SMS if not auto-dispatched)
      isTestNumber,
      smsDispatched,
    };
  }

  /**
   * Verify an OTP code
   *
   * @param params - OTP verification parameters
   * @returns Verification result
   */
  async verifyOtp(params: VerifyOtpParams): Promise<VerifyOtpResult> {
    const { purpose, code } = params;
    const phone = this.normalizePhone(params.phone);

    if (!phone || !code) {
      throw new HttpException(
        "Phone and code are required",
        HttpStatus.BAD_REQUEST,
      );
    }

    // Find the most recent valid OTP for this phone + purpose
    const otpRecord = await this.otpCodeRepository.findOne({
      where: {
        phone,
        purpose,
        consumedAt: null, // Not yet consumed
        expiresAt: { [Op.gt]: new Date() }, // Not expired
      },
      order: [["createdAt", "DESC"]],
    });

    if (!otpRecord) {
      return {
        valid: false,
        message: "No valid OTP found. Please request a new one.",
        code: "OTP_NOT_FOUND",
      };
    }

    // Check if max attempts exceeded
    if (otpRecord.attempts >= otpRecord.maxAttempts) {
      return {
        valid: false,
        message:
          "Maximum verification attempts exceeded. Please request a new OTP.",
        requestId: otpRecord.id,
        code: "OTP_MAX_ATTEMPTS",
      };
    }

    // Increment attempt counter
    await otpRecord.increment("attempts");

    // Verify the OTP
    const isValid = await this.verifyOtpHash(code, otpRecord.codeHash);

    if (!isValid) {
      const remainingAttempts = otpRecord.maxAttempts - otpRecord.attempts - 1;
      return {
        valid: false,
        message: `Incorrect OTP. ${remainingAttempts} attempts remaining.`,
        requestId: otpRecord.id,
        code: "OTP_INVALID",
      };
    }

    // Mark as consumed
    await otpRecord.update({ consumedAt: new Date() });

    // Find or create user
    let user = await this.userRepository.findOne({ where: { phone } });

    if (
      !user &&
      (purpose === OtpPurpose.LOGIN || purpose === OtpPurpose.REGISTER)
    ) {
      // Auto-create user on first login/register
      const shortId = Math.random().toString(36).slice(2, 7);
      user = await this.userRepository.create({
        uuid: uuidv4(),
        phone,
        name: `user_${shortId}`,
        location: "Aşgabat",
        status: true, // Activate on OTP verification
      } as any);
    } else if (user) {
      // Activate user if not already
      if (!user.status) {
        await user.update({ status: true });
      }
    }

    console.log("[OtpService] OTP verified successfully", {
      requestId: otpRecord.id,
      phone,
      purpose,
      userId: user?.uuid,
    });

    return {
      valid: true,
      userId: user?.uuid,
      message: "OTP verified successfully",
      requestId: otpRecord.id,
    };
  }

  /**
   * Update OTP dispatch status (called after SMS delivery)
   */
  async updateDispatchStatus(
    requestId: string,
    status: OtpDispatchStatus,
    providerMessageId?: string,
  ): Promise<void> {
    await this.otpCodeRepository.update(
      {
        dispatchStatus: status,
        providerMessageId: providerMessageId || null,
      },
      { where: { id: requestId } },
    );
  }

  /**
   * Clean up expired OTP records (can be called by a scheduled job)
   */
  async cleanupExpiredOtps(): Promise<number> {
    const result = await this.otpCodeRepository.destroy({
      where: {
        expiresAt: { [Op.lt]: new Date() },
      },
    });
    console.log(`[OtpService] Cleaned up ${result} expired OTP records`);
    return result;
  }

  // ============================================================
  // JWT Token Generation (used after OTP verification)
  // ============================================================

  /**
   * Generate JWT tokens for a verified user
   */
  async generateTokens(
    userId: string,
    phone: string,
  ): Promise<{ accessToken: string; refreshToken: string }> {
    const [accessToken, refreshToken] = await Promise.all([
      this.jwtService.signAsync(
        { uuid: userId, phone },
        {
          secret: this.configService.get<string>("ACCESS_TOKEN_SECRET_KEY"),
          expiresIn: "15m",
        },
      ),
      this.jwtService.signAsync(
        { uuid: userId, phone },
        {
          secret: this.configService.get<string>("REFRESH_TOKEN_SECRET_KEY"),
          expiresIn: "7d",
        },
      ),
    ]);

    // Store hash of refresh token (never store plaintext)
    const refreshTokenHash = await hashToken(refreshToken);
    await this.userRepository.update(
      { refreshTokenHash },
      { where: { uuid: userId } },
    );

    return { accessToken, refreshToken };
  }

  // ============================================================
  // HTTP Endpoint Handlers (for OtpController)
  // ============================================================

  /**
   * Send OTP endpoint handler
   */
  async sendOtp(body: { phone: string }, res: any, req?: any): Promise<any> {
    try {
      const result = await this.createOtp({
        phone: body.phone,
        purpose: OtpPurpose.LOGIN,
        ipAddress: req?.ip,
        userAgent: req?.get?.("user-agent"),
      });

      // Note: The actual SMS dispatch will be handled by the SMS service
      // For now, we return the result and let the caller handle dispatch

      return res.status(HttpStatus.OK).json({
        message: result.smsDispatched
          ? "OTP sent via SMS"
          : result.isTestNumber
            ? "Test OTP generated (use code 12345)"
            : "OTP generated (SMS device not connected)",
        requestId: result.requestId,
        phone: result.phone,
        expiresAt: result.expiresAt,
        smsDispatched: result.smsDispatched || false,
        // For test numbers, return the code so testing can proceed
        ...(result.isTestNumber && this.exposeTestCode
          ? { testCode: result.code }
          : {}),
      });
    } catch (error) {
      const status = error?.status || HttpStatus.INTERNAL_SERVER_ERROR;
      return res
        .status(status)
        .json({
          code: error?.response?.code,
          message: error?.message || "OTP send failed",
        });
    }
  }

  /**
   * Verify OTP endpoint handler (returns JWT tokens on success)
   */
  async checkOtp(
    query: { phone: string; otp: string },
    res: any,
  ): Promise<any> {
    try {
      const result = await this.verifyOtp({
        phone: query.phone,
        purpose: OtpPurpose.LOGIN,
        code: query.otp,
      });

      if (!result.valid) {
        return res.status(HttpStatus.UNAUTHORIZED).json({
          code: result.code || "OTP_INVALID",
          message: result.message,
          requestId: result.requestId,
        });
      }

      // Generate tokens
      const tokens = await this.generateTokens(result.userId!, query.phone);

      return res.status(HttpStatus.OK).json({
        message: "Login successful",
        ...tokens,
      });
    } catch (error) {
      const status = error?.status || HttpStatus.INTERNAL_SERVER_ERROR;
      return res
        .status(status)
        .json({
          code: error?.response?.code,
          message: error?.message || "OTP verification failed",
        });
    }
  }

  /**
   * Generic verification endpoint handler (no token generation)
   */
  async checkVerification(
    query: { phone: string; otp: string },
    res: any,
  ): Promise<any> {
    try {
      const result = await this.verifyOtp({
        phone: query.phone,
        purpose: OtpPurpose.VERIFY_PHONE,
        code: query.otp,
      });

      if (!result.valid) {
        return res.status(HttpStatus.NOT_ACCEPTABLE).json({
          code: result.code || "OTP_INVALID",
          message: result.message,
          response: false,
          requestId: result.requestId,
        });
      }

      return res.status(HttpStatus.OK).json({
        message: "Verification successful",
        response: true,
        userId: result.userId,
      });
    } catch (error) {
      const status = error?.status || HttpStatus.INTERNAL_SERVER_ERROR;
      return res
        .status(status)
        .json({
          code: error?.response?.code,
          message: error?.message || "Verification failed",
        });
    }
  }
}
