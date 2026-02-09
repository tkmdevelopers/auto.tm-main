import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from "@nestjs/common";
import { JwtService } from "@nestjs/jwt";
import { Request } from "express";
import "dotenv/config";

@Injectable()
export class RefreshGuard implements CanActivate {
  constructor(private jwtService: JwtService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const token = this.extractTokenFromHeader(request);

    if (!token) {
      throw new UnauthorizedException({
        code: "TOKEN_INVALID",
        message: "Missing refresh token",
      });
    }
    try {
      const payload = await this.jwtService.verifyAsync(token, {
        secret: process.env.REFRESH_TOKEN_SECRET_KEY,
      });
      request["uuid"] = payload["uuid"];
      return true;
    } catch (error) {
      if (error?.message === "jwt expired") {
        throw new UnauthorizedException({
          code: "TOKEN_EXPIRED",
          message: "Refresh token expired",
        });
      }
      throw new UnauthorizedException({
        code: "TOKEN_INVALID",
        message: "Invalid refresh token",
      });
    }
  }

  private extractTokenFromHeader(request: Request): string | undefined {
    const [type, token] = request.headers.authorization?.split(" ") ?? [];
    return type === "Bearer" ? token : undefined;
  }
}
