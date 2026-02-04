import { Module } from "@nestjs/common";
import { ModelsService } from "./models.service";
import { UtilProviders } from "src/utils/utilsProvider";
import { ModelsController } from "./models.controller";
import { PassportModule } from "@nestjs/passport";
import { JwtModule } from "@nestjs/jwt";

@Module({
  imports: [
    PassportModule.register({ defaultStrategy: "jwt" }),
    JwtModule.register({}),
  ],
  controllers: [ModelsController],
  providers: [ModelsService, ...UtilProviders],
})
export class ModelsModule {}
