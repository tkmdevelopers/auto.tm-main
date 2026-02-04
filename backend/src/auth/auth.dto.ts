import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";

/**
 * Auth DTOs
 *
 * Note: CreateUser and LoginUser have been removed.
 * All authentication now flows through OTP endpoints:
 * - POST /api/v1/otp/send - Request OTP
 * - GET /api/v1/otp/verify - Verify OTP, get tokens
 */

/**
 * Update current user profile
 */
export class UpdateUser {
  @ApiPropertyOptional({ description: "User display name" })
  name?: string;

  @ApiPropertyOptional({ description: "Email address (optional)" })
  email?: string;

  @ApiPropertyOptional({ description: "Phone number" })
  phone?: string;

  @ApiPropertyOptional({ description: "User location" })
  location?: string;
}

/**
 * Find user by UUID
 */
export class FindOne {
  @ApiProperty({ description: "User UUID" })
  uuid: string;
}

/**
 * Update user (admin)
 */
export class Update {
  @ApiPropertyOptional({ description: "User display name" })
  name?: string;

  @ApiPropertyOptional({ description: "User location" })
  location?: string;

  @ApiPropertyOptional({ description: "User permissions array" })
  access?: string[];

  @ApiPropertyOptional({
    description: "User role",
    enum: ["admin", "owner", "user"],
  })
  role?: string;
}

/**
 * Delete user by UUID
 */
export class DeleteOne {
  @ApiProperty({ description: "User UUID to delete" })
  uuid: string;
}

/**
 * Set Firebase Cloud Messaging token
 */
export class firebaseDto {
  @ApiProperty({ description: "Firebase Cloud Messaging token" })
  token: string;
}
