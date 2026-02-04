import { Module } from "@nestjs/common";
import { VideoService } from "./video.service";
import { VideoController } from "./video.controller";
import { UtilProviders } from "src/utils/utilsProvider";

@Module({
  providers: [VideoService, ...UtilProviders],
  controllers: [VideoController],
})
export class VideoModule {}
