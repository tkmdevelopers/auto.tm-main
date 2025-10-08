import { Module } from '@nestjs/common';
import { OtpController } from './otp.controller';
import { OtpService } from './otp.service';
import { ChatGateway } from 'src/chat/chat.gateway';
import { UtilProviders } from 'src/utils/utilsProvider';
import { PassportModule } from '@nestjs/passport';
import { JwtModule } from '@nestjs/jwt';

@Module({
  imports: [
    PassportModule.register({ defaultStrategy: 'jwt' }),
    JwtModule.register({}),
  ],
  controllers: [OtpController],
  providers: [OtpService, ...UtilProviders, ChatGateway],
})
export class OtpModule {}
