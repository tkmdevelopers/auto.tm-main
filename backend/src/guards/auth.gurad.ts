import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Request } from 'express';
import 'dotenv/config';

@Injectable()
export class AuthGuard implements CanActivate {
  constructor(private jwtService: JwtService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const token = this.extractTokenFromHeader(request);
    if (!token) {
      throw new UnauthorizedException({ code: 'TOKEN_INVALID', message: 'Missing or malformed token' });
    }
    try {
      const payload = await this.jwtService.verifyAsync(token, {
        secret: process.env.ACCESS_TOKEN_SECRET_KEY,
      });
      request['uuid'] = payload['uuid'];
      return true;
    } catch (error) {
      if (error?.message === 'jwt expired') {
        throw new UnauthorizedException({ code: 'TOKEN_EXPIRED', message: 'Access token expired' });
      }
      throw new UnauthorizedException({ code: 'TOKEN_INVALID', message: 'Invalid access token' });
    }
  }

  private extractTokenFromHeader(request: Request): string | undefined {
    const [type, token] = request.headers.authorization?.split(' ') ?? [];
    return type === 'Bearer' ? token : undefined;
  }
}
