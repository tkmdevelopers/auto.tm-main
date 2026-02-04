import {
  Table,
  Column,
  Model,
  DataType,
  Default,
  Index,
  CreatedAt,
  UpdatedAt,
} from "sequelize-typescript";
import { ApiProperty } from "@nestjs/swagger";

/**
 * OTP purpose types - extend as needed for other verification flows
 */
export enum OtpPurpose {
  LOGIN = "login",
  REGISTER = "register",
  VERIFY_PHONE = "verify_phone",
  RESET_PASSWORD = "reset_password",
  SENSITIVE_ACTION = "sensitive_action",
}

/**
 * OTP dispatch status for observability
 */
export enum OtpDispatchStatus {
  PENDING = "pending",
  SENT = "sent",
  DELIVERED = "delivered",
  FAILED = "failed",
}

/**
 * Unified OTP codes table
 *
 * Features:
 * - Hash storage (never stores plaintext OTP)
 * - TTL enforcement via expiresAt
 * - Attempt tracking for brute-force protection
 * - Region routing for SMS providers
 * - Dispatch status tracking for observability
 */
@Table({
  tableName: "otp_codes",
  timestamps: true,
  indexes: [
    { fields: ["phone", "purpose"] },
    { fields: ["expiresAt"] },
    { fields: ["createdAt"] },
  ],
})
export class OtpCode extends Model {
  @ApiProperty({ description: "Unique OTP request ID" })
  @Column({
    type: DataType.UUID,
    primaryKey: true,
    defaultValue: DataType.UUIDV4,
  })
  id: string;

  @ApiProperty({ description: "Phone number in E.164 format" })
  @Column({
    type: DataType.STRING(20),
    allowNull: false,
  })
  @Index
  phone: string;

  @ApiProperty({ description: "OTP purpose", enum: OtpPurpose })
  @Column({
    type: DataType.ENUM(...Object.values(OtpPurpose)),
    allowNull: false,
  })
  purpose: OtpPurpose;

  @ApiProperty({ description: "Hashed OTP code (bcrypt)" })
  @Column({
    type: DataType.STRING(255),
    allowNull: false,
  })
  codeHash: string;

  @ApiProperty({ description: "OTP expiration timestamp" })
  @Column({
    type: DataType.DATE,
    allowNull: false,
  })
  expiresAt: Date;

  @ApiProperty({
    description: "Timestamp when OTP was consumed (verified)",
    nullable: true,
  })
  @Column({
    type: DataType.DATE,
    allowNull: true,
  })
  consumedAt: Date | null;

  @ApiProperty({ description: "Number of verification attempts" })
  @Default(0)
  @Column({
    type: DataType.INTEGER,
    allowNull: false,
  })
  attempts: number;

  @ApiProperty({ description: "Maximum allowed verification attempts" })
  @Default(5)
  @Column({
    type: DataType.INTEGER,
    allowNull: false,
  })
  maxAttempts: number;

  @ApiProperty({ description: "Region for SMS routing", nullable: true })
  @Column({
    type: DataType.STRING(50),
    allowNull: true,
  })
  region: string | null;

  @ApiProperty({ description: "Delivery channel" })
  @Default("sms")
  @Column({
    type: DataType.STRING(20),
    allowNull: false,
  })
  channel: string;

  @ApiProperty({ description: "SMS provider message ID", nullable: true })
  @Column({
    type: DataType.STRING(255),
    allowNull: true,
  })
  providerMessageId: string | null;

  @ApiProperty({ description: "OTP dispatch status", enum: OtpDispatchStatus })
  @Default(OtpDispatchStatus.PENDING)
  @Column({
    type: DataType.ENUM(...Object.values(OtpDispatchStatus)),
    allowNull: false,
  })
  dispatchStatus: OtpDispatchStatus;

  @ApiProperty({ description: "IP address of requester", nullable: true })
  @Column({
    type: DataType.STRING(45), // IPv6 max length
    allowNull: true,
  })
  ipAddress: string | null;

  @ApiProperty({ description: "User agent of requester", nullable: true })
  @Column({
    type: DataType.TEXT,
    allowNull: true,
  })
  userAgent: string | null;

  @CreatedAt
  @Column
  createdAt: Date;

  @UpdatedAt
  @Column
  updatedAt: Date;

  /**
   * Check if OTP is expired
   */
  isExpired(): boolean {
    return new Date() > this.expiresAt;
  }

  /**
   * Check if OTP is already consumed
   */
  isConsumed(): boolean {
    return this.consumedAt !== null;
  }

  /**
   * Check if max attempts exceeded
   */
  isMaxAttemptsExceeded(): boolean {
    return this.attempts >= this.maxAttempts;
  }

  /**
   * Check if OTP can be verified (not expired, not consumed, attempts remaining)
   */
  canVerify(): boolean {
    return (
      !this.isExpired() && !this.isConsumed() && !this.isMaxAttemptsExceeded()
    );
  }
}
