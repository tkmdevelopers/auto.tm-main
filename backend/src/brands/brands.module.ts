import { Module } from "@nestjs/common";
import { BrandsService } from "./brands.service";
import { UtilProviders } from "src/utils/utilsProvider";
import { BrandsController } from "./brands.controller";
import { PassportModule } from "@nestjs/passport";
import { JwtModule } from "@nestjs/jwt";

@Module({
  imports: [
    PassportModule.register({ defaultStrategy: "jwt" }),
    JwtModule.register({}),
  ],
  controllers: [BrandsController],
  providers: [BrandsService, ...UtilProviders],
})
export class BrandsModule {}
