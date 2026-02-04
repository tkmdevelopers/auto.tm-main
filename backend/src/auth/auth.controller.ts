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
  Res,
  UseGuards,
  UploadedFile,
  UseInterceptors,
} from "@nestjs/common";
import {
  ApiResponse,
  ApiSecurity,
  ApiTags,
  ApiConsumes,
  ApiOperation,
  ApiBody,
} from "@nestjs/swagger";
import { AuthService } from "./auth.service";
import {
  DeleteOne,
  FindOne,
  firebaseDto,
  Update,
  UpdateUser,
} from "./auth.dto";
import { Request, Response } from "express";
import { AuthGuard } from "src/guards/auth.gurad";
import { RefreshGuard } from "src/guards/refresh.guard";
import { AdminGuard } from "src/guards/admin.guard";
import { FileInterceptor } from "@nestjs/platform-express";
import { muletrOptionsForUsers } from "src/photo/config/multer.config";

/**
 * Auth Controller
 *
 * OTP-only authentication flow:
 * 1. POST /api/v1/otp/send?phone=... - Request OTP
 * 2. GET /api/v1/otp/verify?phone=...&otp=... - Verify OTP, get tokens
 * 3. GET /api/v1/auth/me - Get current user (with token)
 * 4. GET /api/v1/auth/refresh - Refresh access token
 *
 * Note: Email/password login has been removed. All authentication
 * now flows through the OTP endpoints.
 */
@Controller({ path: "auth", version: "1" })
@ApiTags("Auth")
export class AuthController {
  constructor(private authService: AuthService) {}

  // ============================================================
  // Token Management
  // ============================================================

  @Get("refresh")
  @ApiOperation({ summary: "Refresh access token using refresh token" })
  @ApiSecurity("token")
  @UseGuards(RefreshGuard)
  @ApiResponse({
    status: HttpStatus.OK,
    description: "New access token returned",
    schema: {
      example: {
        accessToken: "new-jwt-access-token",
      },
    },
  })
  async refresh(@Req() req: Request) {
    return this.authService.refresh(req);
  }

  @Get("/logout")
  @ApiOperation({ summary: "Logout (invalidate refresh token)" })
  @UseGuards(AuthGuard)
  @ApiSecurity("token")
  @ApiResponse({
    status: HttpStatus.OK,
    description: "Logged out successfully",
    schema: {
      example: {
        message: "Successfully logged out",
      },
    },
  })
  async logout(@Req() req: Request, @Res() res: Response) {
    return this.authService.logout(req, res);
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
    schema: {
      example: {
        uuid: "user-uuid",
        name: "User Name",
        phone: "+99362120020",
        location: "Aşgabat",
        role: "user",
        avatar: null,
      },
    },
  })
  async me(@Req() req: Request, @Res() res: Response) {
    return this.authService.me(req, res);
  }

  @Put()
  @ApiOperation({ summary: "Update current user profile" })
  @UseGuards(AuthGuard)
  @ApiSecurity("token")
  @ApiResponse({
    status: HttpStatus.OK,
    description: "Profile updated successfully",
    schema: {
      example: {
        message: "Successfully changed",
        uuid: "user-uuid",
      },
    },
  })
  async patch(
    @Body() body: UpdateUser,
    @Res() res: Response,
    @Req() req: Request,
  ) {
    return this.authService.patch(body, req, res);
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
    schema: {
      example: {
        message: "Firebase token set successfully",
      },
    },
  })
  async setFirebaseToken(
    @Body() body: firebaseDto,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    return this.authService.setFirebase(body, req, res);
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
    @Req() req: Request,
    @Res() res: Response,
  ) {
    return this.authService.uploadAvatar(file, req, res);
  }

  @Delete("avatar")
  @ApiOperation({ summary: "Delete user avatar" })
  @UseGuards(AuthGuard)
  @ApiSecurity("token")
  @ApiResponse({ status: 200, description: "Avatar deleted successfully" })
  async deleteAvatar(@Req() req: Request, @Res() res: Response) {
    return this.authService.deleteAvatar(req, res);
  }

  // ============================================================
  // Admin Routes
  // ============================================================

  @Get("/users")
  @ApiOperation({ summary: "List all users (admin only)" })
  @UseGuards(AuthGuard)
  @UseGuards(AdminGuard)
  @ApiSecurity("token")
  async findAll(@Req() req: Request, @Res() res: Response) {
    return this.authService.findAll(req, res);
  }

  @Get("/:uuid")
  @ApiOperation({ summary: "Get user by ID (admin only)" })
  @UseGuards(AuthGuard)
  @UseGuards(AdminGuard)
  @ApiSecurity("token")
  async findOne(
    @Param() param: FindOne,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    return this.authService.findOne(param, req, res);
  }

  @Patch("/:uuid")
  @ApiOperation({ summary: "Update user (admin only)" })
  @UseGuards(AuthGuard)
  @UseGuards(AdminGuard)
  @ApiSecurity("token")
  async update(
    @Param() param: FindOne,
    @Body() body: Update,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    return this.authService.update(param, body, req, res);
  }

  @Delete("/:uuid")
  @ApiOperation({ summary: "Delete user (admin only)" })
  @UseGuards(AuthGuard)
  @UseGuards(AdminGuard)
  @ApiSecurity("token")
  async delete(
    @Param() param: DeleteOne,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    return this.authService.deleteOne(param, req, res);
  }
}
