import { HttpException, HttpStatus, Inject, Injectable } from "@nestjs/common";
import {
  DeleteOne,
  FindOne,
  firebaseDto,
  ProfileResponse,
  TokenResponse,
  Update,
  UpdateUser,
} from "./auth.dto";
import { AuthenticatedRequest } from "src/utils/types";
import { User, UserRole } from "./auth.entity";
import { ConfigService } from "@nestjs/config";
import { JwtService } from "@nestjs/jwt";
import { Photo } from "src/photo/photo.entity";
import * as sharp from "sharp";
import * as path from "path";
import * as fs from "fs";
import { promisify } from "util";
import { v4 as uuidv4 } from "uuid";
import { hashToken, validateToken } from "src/utils/token.utils";

const unlinkAsync = promisify(fs.unlink);

/**
 * Auth Service
 *
 * OTP-only authentication:
 * - Registration and login are handled via OtpService (otp/send + otp/verify)
 * - This service handles profile management, token refresh, and admin operations
 *
 * Email/password login has been removed. All authentication
 * now flows through the OTP endpoints.
 */
@Injectable()
export class AuthService {
  constructor(
    @Inject("USERS_REPOSITORY") private Users: typeof User,
    @Inject("PHOTO_REPOSITORY") private photo: typeof Photo,
    private configService: ConfigService,
    private jwtService: JwtService,
  ) {}

  // ============================================================
  // Token Management
  // ============================================================

  /**
   * Refresh access token using refresh token.
   * Implements token rotation: returns both a new access AND refresh token.
   */
  async refresh(req: AuthenticatedRequest): Promise<TokenResponse> {
    const user = await this.Users.findOne({
      where: { uuid: req.uuid },
      attributes: ["uuid", "refreshTokenHash", "phone"],
    });

    if (!user || !user.refreshTokenHash) {
      throw new HttpException(
        { code: "TOKEN_INVALID", message: "Session revoked or user not found" },
        HttpStatus.UNAUTHORIZED,
      );
    }

    const refreshToken = req.get("authorization")?.replace("Bearer", "").trim();

    if (!refreshToken) {
      throw new HttpException(
        { code: "TOKEN_INVALID", message: "Missing refresh token" },
        HttpStatus.UNAUTHORIZED,
      );
    }

    // Compare presented token against stored hash
    const isValid = await validateToken(refreshToken, user.refreshTokenHash);

    if (!isValid) {
      // Reuse detected — revoke session entirely (force re-login)
      await this.Users.update(
        { refreshTokenHash: null },
        { where: { uuid: user.uuid } },
      );
      throw new HttpException(
        {
          code: "TOKEN_REUSE",
          message: "Refresh token reuse detected. Session revoked.",
        },
        HttpStatus.UNAUTHORIZED,
      );
    }

    // Issue new access + new refresh (rotation)
    const [accessToken, newRefreshToken] = await Promise.all([
      this.jwtService.signAsync(
        { uuid: user.uuid, phone: user.phone },
        {
          secret: this.configService.get<string>("ACCESS_TOKEN_SECRET_KEY"),
          expiresIn: "15m",
        },
      ),
      this.jwtService.signAsync(
        { uuid: user.uuid, phone: user.phone },
        {
          secret: this.configService.get<string>("REFRESH_TOKEN_SECRET_KEY"),
          expiresIn: "7d",
        },
      ),
    ]);

    // Store hash of the new refresh token
    const newHash = await hashToken(newRefreshToken);
    await this.Users.update(
      { refreshTokenHash: newHash },
      { where: { uuid: user.uuid } },
    );

    return { accessToken, refreshToken: newRefreshToken };
  }

  /**
   * Logout (invalidate refresh token)
   */
  async logout(req: AuthenticatedRequest) {
    await this.Users.update(
      { refreshTokenHash: null },
      { where: { uuid: req.uuid } },
    );
    return { message: "Successfully logged out" };
  }

  // ============================================================
  // Profile Management
  // ============================================================

  /**
   * Get current user profile
   */
  async me(req: AuthenticatedRequest): Promise<ProfileResponse> {
    const user = await this.Users.findOne({
      where: { uuid: req.uuid },
      include: ["avatar"],
    });

    if (!user) {
      throw new HttpException("User Not Found", HttpStatus.NOT_FOUND);
    }

    return {
      uuid: user.uuid,
      name: user.name,
      email: user.email,
      phone: user.phone,
      location: user.location,
      access: user.access || [],
      role: user.role,
      avatar: user.avatar,
    };
  }

  /**
   * Update current user profile
   */
  async patch(body: UpdateUser, req: AuthenticatedRequest) {
    const { location, email, name, phone } = body;

    await this.Users.update(
      { location, email, name, phone },
      { where: { uuid: req.uuid } },
    );

    return {
      message: "Successfully changed",
      uuid: req.uuid,
    };
  }

  // ============================================================
  // Avatar Management
  // ============================================================

  /**
   * Upload user avatar
   */
  async uploadAvatar(file: Express.Multer.File, req: AuthenticatedRequest) {
    const userId = req.uuid;

    // Check if user exists
    const user = await this.Users.findOne({ where: { uuid: userId } });
    if (!user) {
      throw new HttpException("User Not Found", HttpStatus.NOT_FOUND);
    }

    const originalPath = file.path;
    const uploadDir = path.dirname(originalPath);

    const sizes = [
      { name: "large", width: 1024 },
      { name: "medium", width: 512 },
      { name: "small", width: 256 },
    ];

    const paths: Record<string, string> = {
      small: "",
      medium: "",
      large: "",
    };

    for (const size of sizes) {
      const resizedFilePath = path.join(
        uploadDir,
        `${size.name}_${uuidv4()}${path.extname(file.originalname)}`,
      );
      await sharp(originalPath).resize(size.width).toFile(resizedFilePath);
      paths[size.name] = resizedFilePath;
    }

    // Create or update photo record
    const [photo, created] = await this.photo.findOrCreate({
      where: { userId },
      defaults: {
        uuid: uuidv4(),
        originalPath,
        path: paths,
        userId,
      },
    });

    if (!created) {
      // Update existing photo
      await photo.update({
        originalPath,
        path: paths,
      });
    }

    return {
      message: "Avatar uploaded successfully",
      uuid: photo.uuid,
    };
  }

  /**
   * Delete user avatar
   */
  async deleteAvatar(req: AuthenticatedRequest) {
    const userId = req.uuid;

    const photo = await this.photo.findOne({ where: { userId } });
    if (!photo) {
      throw new HttpException("Avatar not found", HttpStatus.NOT_FOUND);
    }

    const baseDir = path.join(__dirname, "..", "..");

    // Delete all resized versions and original file
    const photoPaths = photo.path as Record<string, string>;
    const sizes = ["small", "medium", "large"];
    for (const size of sizes) {
      if (photoPaths?.[size]) {
        const filePath = path.join(baseDir, photoPaths[size]);
        try {
          if (fs.existsSync(filePath)) {
            await unlinkAsync(filePath);
          }
        } catch (fsError) {
          console.warn(`Failed to delete ${size} file:`, fsError?.message);
        }
      }
    }

    // Delete original file if exists
    if (photo.originalPath) {
      const originalFilePath = path.join(baseDir, photo.originalPath);
      try {
        if (fs.existsSync(originalFilePath)) {
          await unlinkAsync(originalFilePath);
        }
      } catch (fsError) {
        console.warn(`Failed to delete original file:`, fsError?.message);
      }
    }

    await photo.destroy();

    return { message: "Avatar deleted successfully" };
  }

  // ============================================================
  // Firebase Token
  // ============================================================

  /**
   * Set Firebase Cloud Messaging token
   */
  async setFirebase(body: firebaseDto, req: AuthenticatedRequest) {
    const { token } = body;
    await this.Users.update(
      { firebaseToken: token },
      { where: { uuid: req.uuid } },
    );
    return { message: "Firebase token set successfully" };
  }

  // ============================================================
  // Admin Operations
  // ============================================================

  /**
   * List all users (admin only)
   */
  async findAll() {
    return this.Users.findAll({
      include: ["avatar"],
    });
  }

  /**
   * Get user by ID (admin only)
   */
  async findOne(param: FindOne) {
    const { uuid } = param;
    const user = await this.Users.findOne({
      where: { uuid },
      include: ["avatar"],
    });
    if (!user) {
      throw new HttpException("User Not Found", HttpStatus.NOT_FOUND);
    }
    return user;
  }

  /**
   * Update user (admin only)
   */
  async update(param: FindOne, body: Update) {
    const { uuid } = param;
    const { location, name, access, role } = body;

    await this.Users.update(
      { location, name, access, role },
      { where: { uuid } },
    );

    return {
      message: "Successfully changed",
      uuid: uuid,
    };
  }

  /**
   * Delete user (admin only)
   */
  async deleteOne(param: DeleteOne) {
    const { uuid } = param;
    const user = await this.Users.destroy({ where: { uuid } });
    if (!user) {
      throw new HttpException("User Not Found", HttpStatus.NOT_FOUND);
    }
    return { message: "User Successfully deleted" };
  }
}
