import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Inject,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Request } from 'express';
import 'dotenv/config';
import { User } from 'src/auth/auth.entity';

@Injectable()
export class AdminGuard implements CanActivate {
  constructor(
    private jwtService: JwtService,
    @Inject('USERS_REPOSITORY') private Users: typeof User,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const token = this.extractTokenFromHeader(request);
    const uuid = await this.extractUUIDFromToken(token);
    if (!uuid) {
      throw new UnauthorizedException({ code: 'TOKEN_INVALID', message: 'Missing or invalid token' });
    }
    const admin = await this.Users.findOne({ where: { uuid } });
    if (!admin || admin.role !== 'admin') {
      throw new ForbiddenException({ code: 'FORBIDDEN', message: 'Admin access required' });
    }
    request['uuid'] = uuid;
    return true;
  }

  private extractTokenFromHeader(request: Request): string | undefined {
    const [type, token] = request.headers.authorization?.split(' ') ?? [];
    return type === 'Bearer' ? token : undefined;
  }

  private async extractUUIDFromToken(token?: string): Promise<string | undefined> {
    if (!token) {
      throw new UnauthorizedException({ code: 'TOKEN_INVALID', message: 'Missing token' });
    }
    try {
      const payload = await this.jwtService.verifyAsync(token, {
        secret: process.env.ACCESS_TOKEN_SECRET_KEY,
      });
      return payload?.uuid;
    } catch (error) {
      if (error?.message === 'jwt expired') {
        throw new UnauthorizedException({ code: 'TOKEN_EXPIRED', message: 'Access token expired' });
      }
      throw new UnauthorizedException({ code: 'TOKEN_INVALID', message: 'Invalid access token' });
    }
  }
}
