import { HttpException, HttpStatus, Inject, Injectable } from "@nestjs/common";
import {
  DeleteOne,
  FindOne,
  firebaseDto,
  Update,
  UpdateUser,
} from "./auth.dto";
import { Request, Response } from "express";
import { AuthenticatedRequest } from "src/utils/types";
import { User } from "./auth.entity";
import { ConfigService } from "@nestjs/config";
import { JwtService } from "@nestjs/jwt";
import { Photo } from "src/photo/photo.entity";
import * as sharp from "sharp";
import * as path from "path";
import * as fs from "fs";
import * as bcrypt from "bcryptjs";
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
   * Implements reuse detection: if the presented token doesn't match the stored
   * hash, assume compromise and revoke the session.
   */
  async refresh(req: any): Promise<any> {
    const user = await this.Users.findOne({
      where: { uuid: req?.uuid },
      attributes: ["uuid", "refreshTokenHash", "phone"],
    });

    if (!user || !user.refreshTokenHash) {
      throw new HttpException(
        { code: "TOKEN_INVALID", message: "Session revoked or user not found" },
        HttpStatus.UNAUTHORIZED,
      );
    }

    const refreshToken = req
      .get("authorization")
      .replace("Bearer", "")
      .trim();

    // Compare presented token against stored hash
    const isValid = await validateToken(refreshToken, user.refreshTokenHash);

    if (!isValid) {
      // Reuse detected — revoke session entirely (force re-login)
      await this.Users.update(
        { refreshTokenHash: null },
        { where: { uuid: user.uuid } },
      );
      throw new HttpException(
        { code: "TOKEN_REUSE", message: "Refresh token reuse detected. Session revoked." },
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
  async logout(req: AuthenticatedRequest, res: Response) {
    try {
      await this.Users.update(
        { refreshTokenHash: null },
        { where: { uuid: req?.uuid } },
      );
      return res.status(HttpStatus.OK).json({
        message: "Successfully logged out",
      });
    } catch (error) {
      console.error("[AuthService] Logout error:", error);
      return res.status(500).json({
        message: "Internal server error!",
        detail: error?.message || "Unknown",
      });
    }
  }

  // ============================================================
  // Profile Management
  // ============================================================

  /**
   * Get current user profile
   */
  async me(req: AuthenticatedRequest, res: Response) {
    try {
      const user = await this.Users.findOne({
        where: { uuid: req?.uuid },
        include: ["avatar"],
      });
      if (!user) {
        throw new HttpException("User Not Found", HttpStatus.NOT_FOUND);
      }
      return res.status(HttpStatus.OK).json({
        uuid: user.uuid,
        name: user.name,
        email: user.email,
        phone: user.phone,
        location: user.location,
        access: user.access,
        role: user.role,
        avatar: user.avatar,
      });
    } catch (error) {
      if (error?.status) {
        return res.status(error.status).json(error);
      }
      console.error("[AuthService] Me error:", error);
      return res.status(500).json({
        message: "Internal server error!",
        detail: error?.message || "Unknown",
      });
    }
  }

  /**
   * Update current user profile
   */
  async patch(body: UpdateUser, req: AuthenticatedRequest, res: Response) {
    try {
      const { location, email, name, phone } = body;

      // Note: Password updates removed - OTP-only auth
      const updatedUser = await this.Users.update(
        { location, email, name, phone },
        { where: { uuid: req?.uuid } },
      );

      if (updatedUser) {
        return res.status(HttpStatus.OK).json({
          message: "Successfully changed",
          uuid: req?.uuid,
        });
      }
    } catch (error) {
      if (error?.status) {
        return res.status(error.status).json(error);
      }
      console.error("[AuthService] Patch error:", error);
      return res.status(500).json({
        message: "Internal server error!",
        detail: error?.parent?.detail || "Unknown",
      });
    }
  }

  // ============================================================
  // Avatar Management
  // ============================================================

  /**
   * Upload user avatar
   */
  async uploadAvatar(
    file: Express.Multer.File,
    req: AuthenticatedRequest,
    res: Response,
  ) {
    try {
      const userId = req?.uuid;

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

      const paths = {
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

      return res.status(200).json({
        message: "Avatar uploaded successfully",
        uuid: photo.uuid,
      });
    } catch (error) {
      console.error("Error uploading avatar:", error);
      return res.status(500).json({
        message: "Internal server error!",
        error: error?.message,
      });
    }
  }

  /**
   * Delete user avatar
   */
  async deleteAvatar(req: AuthenticatedRequest, res: Response) {
    try {
      const userId = req?.uuid;

      const photo = await this.photo.findOne({ where: { userId } });
      if (!photo) {
        return res.status(404).json({ message: "Avatar not found" });
      }

      const baseDir = path.join(__dirname, "..", "..");

      // Delete all resized versions and original file
      for (const size of ["small", "medium", "large"]) {
        const filePath = path.join(baseDir, photo.path?.[size]);
        try {
          if (fs.existsSync(filePath)) {
            await unlinkAsync(filePath);
          }
        } catch (fsError) {
          console.warn(`Failed to delete ${size} file:`, fsError.message);
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
          console.warn(`Failed to delete original file:`, fsError.message);
        }
      }

      await photo.destroy();

      return res.status(200).json({ message: "Avatar deleted successfully" });
    } catch (error) {
      console.error("Error deleting avatar:", error);
      return res.status(500).json({
        message: "Internal server error!",
        error: error?.message,
      });
    }
  }

  // ============================================================
  // Firebase Token
  // ============================================================

  /**
   * Set Firebase Cloud Messaging token
   */
  async setFirebase(body: firebaseDto, req: AuthenticatedRequest, res: Response) {
    try {
      const { token } = body;
      await this.Users.update(
        { firebaseToken: token },
        { where: { uuid: req?.uuid } },
      );
      return res.status(HttpStatus.OK).json({
        message: "Firebase token set successfully",
      });
    } catch (error) {
      console.error("[AuthService] SetFirebase error:", error);
      return res.status(500).json({
        message: "Internal server error!",
        detail: error?.message || "Unknown",
      });
    }
  }

  // ============================================================
  // Admin Operations
  // ============================================================

  /**
   * List all users (admin only)
   */
  async findAll(req: AuthenticatedRequest, res: Response) {
    try {
      const users = await this.Users.findAll({
        include: ["avatar"],
      });
      return res.status(HttpStatus.OK).json(users);
    } catch (error) {
      console.error("[AuthService] FindAll error:", error);
      return res.status(500).json({
        message: "Internal server error!",
        detail: error?.message || "Unknown",
      });
    }
  }

  /**
   * Get user by ID (admin only)
   */
  async findOne(param: FindOne, req: AuthenticatedRequest, res: Response) {
    try {
      const { uuid } = param;
      const user = await this.Users.findOne({
        where: { uuid },
        include: ["avatar"],
      });
      if (!user) {
        throw new HttpException("User Not Found", HttpStatus.NOT_FOUND);
      }
      return res.status(HttpStatus.OK).json(user);
    } catch (error) {
      if (error?.status) {
        return res.status(error.status).json(error);
      }
      console.error("[AuthService] FindOne error:", error);
      return res.status(500).json({
        message: "Internal server error!",
        detail: error?.message || "Unknown",
      });
    }
  }

  /**
   * Update user (admin only)
   */
  async update(
    param: FindOne,
    body: Update,
    req: AuthenticatedRequest,
    res: Response,
  ) {
    try {
      const { uuid } = param;
      const { location, name, access, role } = body;

      // Note: Password updates removed - OTP-only auth
      const updatedUser = await this.Users.update(
        { location, name, access, role },
        { where: { uuid } },
      );

      if (updatedUser) {
        return res.status(HttpStatus.OK).json({
          message: "Successfully changed",
          uuid: uuid,
        });
      }
    } catch (error) {
      if (error?.status) {
        return res.status(error.status).json(error);
      }
      console.error("[AuthService] Update error:", error);
      return res.status(500).json({
        message: "Internal server error!",
        detail: error?.parent?.detail || "Unknown",
      });
    }
  }

  /**
   * Delete user (admin only)
   */
  async deleteOne(param: DeleteOne, req: AuthenticatedRequest, res: Response) {
    try {
      const { uuid } = param;
      const user = await this.Users.destroy({ where: { uuid } });
      if (!user) {
        throw new HttpException("User Not Found", HttpStatus.NOT_FOUND);
      }
      return res.status(HttpStatus.OK).json({
        message: "User Successfully deleted",
      });
    } catch (error) {
      if (error?.status) {
        return res.status(error.status).json(error);
      }
      console.error("[AuthService] DeleteOne error:", error);
      return res.status(500).json({
        message: "Internal server error!",
        detail: error?.message || "Unknown",
      });
    }
  }
}
