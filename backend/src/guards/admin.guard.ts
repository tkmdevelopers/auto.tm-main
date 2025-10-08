/* eslint-disable prettier/prettier */
import {
  CanActivate,
  ExecutionContext,
  Inject,
  Injectable,
  NotAcceptableException,
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
    const token = await this.extractTokenFromHeader(request);
    const uuid = await this.extractUUIDFromHeader(token);
    console.log(uuid);
    if (!uuid) {
      throw new UnauthorizedException();
    }
    try {
      const admin = await this.Users.findOne({
        where: { uuid },
      });
      if (!(admin?.role == 'admin')) {
        throw new NotAcceptableException();
      }

      return true;
      // 💡 We're assigning the payload to the request object here
      // so that we can access it in our route handlers
    } catch (error) {
      console.log(error);
      throw new NotAcceptableException();
    }
    return true;
  }

  private extractTokenFromHeader(request: Request): string | undefined {
    const [type, token] = request.headers.authorization?.split(' ') ?? [];

    return type === 'Bearer' ? token : undefined;
  }
  private async extractUUIDFromHeader(token?: string) {
    if (!token) {
      throw new UnauthorizedException();
    }
    try {
      const payload = await this.jwtService.verifyAsync(token, {
        secret: process.env.ACCESS_TOKEN_SECRET_KEY,
      });

      return payload?.uuid;
    } catch (error) {
      console.log(error);
      if (error?.message == 'jwt expired') {
        throw new NotAcceptableException();
      }
      throw new UnauthorizedException();
    }
  }
}
