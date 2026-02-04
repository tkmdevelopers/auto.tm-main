import { Module } from "@nestjs/common";
import { VlogController } from "./vlog.controller";
import { VlogService } from "./vlog.service";
import { UtilProviders } from "src/utils/utilsProvider";
import { PassportModule } from "@nestjs/passport";
import { JwtModule } from "@nestjs/jwt";

@Module({
  imports: [
    PassportModule.register({ defaultStrategy: "jwt" }),
    JwtModule.register({}),
  ],
  controllers: [VlogController],
  providers: [VlogService, ...UtilProviders],
})
export class VlogModule {}
