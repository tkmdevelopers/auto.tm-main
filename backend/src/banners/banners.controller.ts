import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Query,
  Req,
  Res,
  UseGuards,
} from "@nestjs/common";
import { ApiSecurity, ApiTags } from "@nestjs/swagger";
import { BannersService } from "./banners.service";
import { Request, Response } from "express";
import { BannerUUID, FindAllBanners } from "./banners.dto";
import { AuthGuard } from "src/guards/auth.guard";
import { AdminGuard } from "src/guards/admin.guard";

@Controller({
  path: "banners",
  version: "1",
})
@ApiTags("Banners")
export class BannersController {
  constructor(private bannersService: BannersService) {}
  @Get()
  // @ApiSecurity('token')
  // @UseGuards(AuthGuard)
  async findAll(
    @Res() res: Response,
    @Req() req: Request,
    @Query() query: FindAllBanners,
  ) {
    return this.bannersService.findAll(res, req, query);
  }
  @ApiSecurity("token")
  @UseGuards(AuthGuard)
  @UseGuards(AdminGuard)
  @Post()
  async create(@Req() req: Request, @Res() res: Response) {
    return this.bannersService.create(req, res);
  }
  @ApiSecurity("token")
  @UseGuards(AuthGuard)
  @UseGuards(AdminGuard)
  @Delete(":uuid")
  async delete(
    @Res() res: Response,
    @Req() req: any,
    @Param() param: BannerUUID,
  ) {
    return this.bannersService.deleteBanner(res, req, param);
  }
  @Get(":uuid")
  async findOne(
    @Res() res: Response,
    @Req() req: any,
    @Param() param: BannerUUID,
  ) {
    return this.bannersService.getOne(res, req, param);
  }
}
