import { Module } from '@nestjs/common';
import { SequelizeModule } from '@nestjs/sequelize';
import { NotificationsController } from './notification.controller';
import { NotificationService } from './notification.service';
import { NotificationHistory } from './notification.entity';
import { User } from 'src/auth/auth.entity';
import { Brands } from 'src/brands/brands.entity';
import { NotificationProvider } from './notification.provider';
import { UtilProviders } from 'src/utils/utilsProvider';
import { PassportModule } from '@nestjs/passport';
import { JwtModule } from '@nestjs/jwt';

@Module({
  imports: [
    PassportModule.register({ defaultStrategy: 'jwt' }),
    JwtModule.register({
      secret: process.env.JWT_SECRET,
      signOptions: { expiresIn: '1h' },
    }),
  ],
  controllers: [NotificationsController],
  providers: [NotificationService, ...UtilProviders],
  exports: [NotificationService],
})
export class NotificationModule {}
