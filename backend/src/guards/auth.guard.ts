import {
  CanActivate,
  ExecutionContext,
  Inject,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Request } from 'express';
import { User } from 'src/auth/auth.entity';
import 'dotenv/config';

@Injectable()
export class AuthGuard implements CanActivate {
  constructor(
    private jwtService: JwtService,
    @Inject('USERS_REPOSITORY') private usersRepo: typeof User,
  ) {}

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
      
      // Check if user still exists in database
      const user = await this.usersRepo.findOne({
        where: { uuid: payload['uuid'] },
        attributes: ['uuid'], // minimal query for performance
      });
      
      if (!user) {
        throw new UnauthorizedException({
          code: 'USER_DELETED',
          message: 'This account has been deleted by an administrator',
        });
      }
      
      request['uuid'] = payload['uuid'];
      return true;
    } catch (error) {
      // Re-throw our custom errors
      if (error instanceof UnauthorizedException) {
        throw error;
      }
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
