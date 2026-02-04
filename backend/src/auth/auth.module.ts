import { Module } from "@nestjs/common";
import { AuthController } from "./auth.controller";
import { AuthService } from "./auth.service";
import { PassportModule } from "@nestjs/passport";
import { JwtModule } from "@nestjs/jwt";
import { UtilProviders } from "src/utils/utilsProvider";
import { JwtStrategy } from "src/strategy/AccessToken.strategy";
import { RefreshTokenStrategy } from "src/strategy/RefreshToken.strategy";

@Module({
  imports: [
    PassportModule.register({ defaultStrategy: "jwt" }),
    JwtModule.register({}),
  ],
  controllers: [AuthController],
  providers: [AuthService, ...UtilProviders, JwtStrategy, RefreshTokenStrategy],
})
export class AuthModule {}
