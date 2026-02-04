import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  Req,
  Res,
  UseGuards,
  Query,
} from "@nestjs/common";
import { ApiTags, ApiSecurity } from "@nestjs/swagger";
import { VlogService } from "./vlog.service";
import { Request, Response } from "express";
import { AuthGuard } from "src/guards/auth.gurad";
import { CreateVlogDto, FindAllVlogDto, UpdateVlogDto } from "./vlog.dto";

@Controller({
  path: "vlog",
  version: "1",
})
@ApiTags("Vlog and Functions")
export class VlogController {
  constructor(private vlogService: VlogService) {}

  @ApiSecurity("token")
  @UseGuards(AuthGuard)
  @Post()
  async create(
    @Body() body: CreateVlogDto,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    return this.vlogService.create(body, req, res);
  }

  @Get()
  async findAll(
    @Query() query: FindAllVlogDto,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    return this.vlogService.findAll(query, req, res);
  }

  @ApiSecurity("token")
  @UseGuards(AuthGuard)
  @Get(":id")
  async findOne(
    @Param("id") id: string,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    return this.vlogService.findOne(id, req, res);
  }

  @ApiSecurity("token")
  @UseGuards(AuthGuard)
  @Patch(":id")
  async update(
    @Param("id") id: string,
    @Body() body: UpdateVlogDto,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    return this.vlogService.update(id, body, req, res);
  }

  @ApiSecurity("token")
  @UseGuards(AuthGuard)
  @Delete(":id")
  async remove(
    @Param("id") id: string,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    return this.vlogService.remove(id, req, res);
  }
}
