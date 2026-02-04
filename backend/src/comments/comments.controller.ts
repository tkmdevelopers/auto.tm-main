import {
  Body,
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Param,
  Query,
  Req,
  Res,
  UseGuards,
} from "@nestjs/common";
import { ApiSecurity, ApiTags } from "@nestjs/swagger";
import { CommentsService } from "./comments.service";
import { createCommets, findAllComments } from "./comments.dto";
import { Request, Response } from "express";
import { AuthGuard } from "src/guards/auth.gurad";

@Controller({
  path: "comments",
  version: "1",
})
@ApiTags("Comments and Reply functions")
export class CommentsController {
  constructor(private commentsService: CommentsService) {}

  @ApiSecurity("token")
  @UseGuards(AuthGuard)
  @Post()
  async create(
    @Body() body: createCommets,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    return this.commentsService.create(body, req, res);
  }

  @ApiSecurity("token")
  @UseGuards(AuthGuard)
  @Get()
  async findAll(
    @Query() body: findAllComments,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    return this.commentsService.findAll(body, req, res);
  }

  @ApiSecurity("token")
  @UseGuards(AuthGuard)
  @Get(":id")
  async findOne(
    @Param("id") id: string,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    return this.commentsService.findOne(id, req, res);
  }

  @ApiSecurity("token")
  @UseGuards(AuthGuard)
  @Patch(":id")
  async update(
    @Param("id") id: string,
    @Body() body: any,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    return this.commentsService.update(id, body, req, res);
  }

  @ApiSecurity("token")
  @UseGuards(AuthGuard)
  @Delete(":id")
  async remove(
    @Param("id") id: string,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    return this.commentsService.remove(id, req, res);
  }
}
