import { Module } from "@nestjs/common";
import { AppController } from "./app.controller";
import { AppService } from "./app.service";
import { AuthModule } from "./auth/auth.module";
import { UtilProviders } from "./utils/utilsProvider";
import { DatabaseModule } from "./database/database.module";
import { MailService } from "./mail/mail.service";
import { OtpController } from "./otp/otp.controller";
import { ConfigModule } from "@nestjs/config";
import { JwtModule } from "@nestjs/jwt";
import { PostModule } from "./post/post.module";
import { BrandsModule } from "./brands/brands.module";
import { ModelsService } from "./models/models.service";
import { ColorsService } from "./colors/colors.service";
import { ModelsModule } from "./models/models.module";
import { PhotoModule } from "./photo/photo.module";
import { join } from "path";
import { ServeStaticModule } from "@nestjs/serve-static";
import { BannersModule } from "./banners/banners.module";
import { CategoriesModule } from "./categories/categories.module";
import { CommentsModule } from "./comments/comments.module";
import { AdminsModule } from "./admins/admins.module";
import { VlogModule } from "./vlog/vlog.module";
import { SubscriptionModule } from "./subscription/subscription.module";
import { VideoModule } from "./video/video.module";
import { NotificationModule } from "./notification/notification.module";
import { OtpModule } from "./otp/otp.module";
import { OtpService } from "./otp/otp.service";
import { ChatGateway } from "./chat/chat.gateway";
import { FileModule } from "./file/file.module";
import { SmsModule } from "./sms/sms.module";

@Module({
  imports: [
    AuthModule,
    SmsModule,
    DatabaseModule,
    JwtModule.register({
      secret: process.env.TOKEN_SECRET_KEY,
    }),
    ConfigModule.forRoot({
      isGlobal: true,
    }),
    ServeStaticModule.forRoot({
      rootPath: join(__dirname, "..", "uploads"),
      serveRoot: "/uploads",
    }),
    PostModule,
    BrandsModule,
    ModelsModule,
    OtpModule,
    PhotoModule,
    BannersModule,
    CategoriesModule,
    CommentsModule,
    AdminsModule,
    VlogModule,
    SubscriptionModule,
    VideoModule,
    NotificationModule,
    FileModule,
  ],
  controllers: [AppController, OtpController],
  providers: [
    AppService,
    OtpService,
    ChatGateway,
    ...UtilProviders,
    MailService,
    ModelsService,
    ColorsService,
  ],
})
export class AppModule {}
