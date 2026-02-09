import {
  Body,
  Controller,
  Delete,
  Get,
  HttpStatus,
  Param,
  Patch,
  Post,
  Put,
  Req,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from "@nestjs/common";
import {
  ApiConsumes,
  ApiOperation,
  ApiResponse,
  ApiSecurity,
  ApiTags,
} from "@nestjs/swagger";
import { AuthService } from "./auth.service";
import {
  DeleteOne,
  FindOne,
  firebaseDto,
  ProfileResponse,
  TokenResponse,
  Update,
  UpdateUser,
} from "./auth.dto";
import { AuthGuard } from "src/guards/auth.guard";
import { RefreshGuard } from "src/guards/refresh.guard";
import { AdminGuard } from "src/guards/admin.guard";
import { FileInterceptor } from "@nestjs/platform-express";
import { muletrOptionsForUsers } from "src/photo/config/multer.config";
import { AuthenticatedRequest } from "src/utils/types";

/**
 * Auth Controller
 *
 * OTP-only authentication flow:
 * 1. POST /api/v1/otp/send       - Request OTP (body: { phone })
 * 2. POST /api/v1/otp/verify      - Verify OTP (body: { phone, otp }) → { accessToken, refreshToken }
 * 3. GET  /api/v1/auth/me          - Get current user (Bearer access token)
 * 4. POST /api/v1/auth/refresh     - Rotate tokens (Bearer refresh token) → { accessToken, refreshToken }
 * 5. POST /api/v1/auth/logout      - Invalidate session (Bearer access token)
 */
@Controller({ path: "auth", version: "1" })
@ApiTags("Auth")
export class AuthController {
  constructor(private authService: AuthService) {}

  // ============================================================
  // Token Management
  // ============================================================

  @Post("refresh")
  @ApiOperation({ summary: "Rotate tokens — returns new access + refresh" })
  @ApiSecurity("token")
  @UseGuards(RefreshGuard)
  @ApiResponse({
    status: HttpStatus.OK,
    description: "Rotated tokens returned",
    type: TokenResponse,
  })
  @ApiResponse({
    status: HttpStatus.UNAUTHORIZED,
    description: "Token reuse detected or invalid refresh token",
  })
  async refresh(@Req() req: AuthenticatedRequest): Promise<TokenResponse> {
    return this.authService.refresh(req);
  }

  @Post("logout")
  @ApiOperation({ summary: "Logout (invalidate refresh token)" })
  @UseGuards(AuthGuard)
  @ApiSecurity("token")
  @ApiResponse({
    status: HttpStatus.OK,
    description: "Logged out successfully",
  })
  async logout(@Req() req: AuthenticatedRequest) {
    return this.authService.logout(req);
  }

  // ============================================================
  // Current User
  // ============================================================

  @Get("/me")
  @ApiOperation({ summary: "Get current authenticated user" })
  @UseGuards(AuthGuard)
  @ApiSecurity("token")
  @ApiResponse({
    status: HttpStatus.OK,
    description: "Current user data",
    type: ProfileResponse,
  })
  async me(@Req() req: AuthenticatedRequest): Promise<ProfileResponse> {
    return this.authService.me(req);
  }

  @Put()
  @ApiOperation({ summary: "Update current user profile" })
  @UseGuards(AuthGuard)
  @ApiSecurity("token")
  @ApiResponse({
    status: HttpStatus.OK,
    description: "Profile updated successfully",
  })
  async patch(@Body() body: UpdateUser, @Req() req: AuthenticatedRequest) {
    return this.authService.patch(body, req);
  }

  // ============================================================
  // Firebase Token
  // ============================================================

  @Put("setFirebase")
  @ApiOperation({ summary: "Set Firebase Cloud Messaging token" })
  @UseGuards(AuthGuard)
  @ApiSecurity("token")
  @ApiResponse({
    status: HttpStatus.OK,
    description: "Firebase token set successfully",
  })
  async setFirebaseToken(
    @Body() body: firebaseDto,
    @Req() req: AuthenticatedRequest,
  ) {
    return this.authService.setFirebase(body, req);
  }

  // ============================================================
  // Avatar Management
  // ============================================================

  @Post("avatar")
  @ApiOperation({ summary: "Upload user avatar" })
  @UseGuards(AuthGuard)
  @ApiSecurity("token")
  @UseInterceptors(FileInterceptor("file", muletrOptionsForUsers))
  @ApiConsumes("multipart/form-data")
  @ApiResponse({ status: 200, description: "Avatar uploaded successfully" })
  async uploadAvatar(
    @UploadedFile() file: Express.Multer.File,
    @Req() req: AuthenticatedRequest,
  ) {
    return this.authService.uploadAvatar(file, req);
  }

  @Delete("avatar")
  @ApiOperation({ summary: "Delete user avatar" })
  @UseGuards(AuthGuard)
  @ApiSecurity("token")
  @ApiResponse({ status: 200, description: "Avatar deleted successfully" })
  async deleteAvatar(@Req() req: AuthenticatedRequest) {
    return this.authService.deleteAvatar(req);
  }

  // ============================================================
  // Admin Routes
  // ============================================================

  @Get("/users")
  @ApiOperation({ summary: "List all users (admin only)" })
  @UseGuards(AuthGuard, AdminGuard)
  @ApiSecurity("token")
  async findAll() {
    return this.authService.findAll();
  }

  @Get("/:uuid")
  @ApiOperation({ summary: "Get user by ID (admin only)" })
  @UseGuards(AuthGuard, AdminGuard)
  @ApiSecurity("token")
  async findOne(@Param() param: FindOne) {
    return this.authService.findOne(param);
  }

  @Patch("/:uuid")
  @ApiOperation({ summary: "Update user (admin only)" })
  @UseGuards(AuthGuard, AdminGuard)
  @ApiSecurity("token")
  async update(@Param() param: FindOne, @Body() body: Update) {
    return this.authService.update(param, body);
  }

  @Delete("/:uuid")
  @ApiOperation({ summary: "Delete user (admin only)" })
  @UseGuards(AuthGuard, AdminGuard)
  @ApiSecurity("token")
  async delete(@Param() param: DeleteOne) {
    return this.authService.deleteOne(param);
  }
}
