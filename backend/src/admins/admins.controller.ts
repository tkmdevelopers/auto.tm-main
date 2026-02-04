import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Put,
  Req,
  Res,
  UseGuards,
} from "@nestjs/common";
import { ApiSecurity, ApiTags } from "@nestjs/swagger";
import { AdminsService } from "./admins.service";
import { AuthGuard } from "src/guards/auth.gurad";
import { AdminGuard } from "src/guards/admin.guard";
import { Request, Response } from "express";
import { FindOne, updateAdmin } from "./admins.dto";

@Controller({
  path: "admins",
  version: "1",
})
@ApiSecurity("token")
@ApiTags("admin")
export class AdminsController {
  constructor(private adminService: AdminsService) {}

  @UseGuards(AuthGuard)
  @UseGuards(AdminGuard)
  @Get()
  async findAll(@Req() req: Request, @Res() res: Response) {
    return this.adminService.findAll(req, res);
  }
  @UseGuards(AuthGuard)
  @UseGuards(AdminGuard)
  @Get("/:uuid")
  async findOne(
    @Param() param: FindOne,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    return this.adminService.findOne(param, req, res);
  }
  @UseGuards(AuthGuard)
  @UseGuards(AdminGuard)
  @Patch("/:uuid")
  async update(
    @Param() param: FindOne,
    @Req() req: Request,
    @Res() res: Response,
    @Body() body: updateAdmin,
  ) {
    return this.adminService.updateAdmin(param, req, res, body);
  }

  // @UseGuards(AuthGuard)
  // // @Put("setAdmin")
  // // async setAdmin(){
  // //   return this.adminService.setAdmin()
  // // }
}
