import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Put,
  Query,
  Req,
  Res,
  UseGuards,
} from "@nestjs/common";
import { ApiSecurity, ApiTags } from "@nestjs/swagger";
import { CategoriesService } from "./categories.service";
import {
  createCategories,
  findAllCategories,
  findOneCat,
} from "./categories.dto";
import { Request, Response } from "express";
import { AuthGuard } from "src/guards/auth.guard";
import { AdminGuard } from "src/guards/admin.guard";

@Controller({
  path: "categories",
  version: "1",
})
@ApiTags("Categories")
export class CategoriesController {
  constructor(private categoriesService: CategoriesService) {}
  @Get()
  async findAll(
    @Query() query: findAllCategories,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    return this.categoriesService.findAll(query, req, res);
  }
  @ApiSecurity("token")
  @UseGuards(AuthGuard)
  @Post()
  async create(
    @Body() body: createCategories,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    return this.categoriesService.create(body, req, res);
  }
  @Get(":uuid")
  async getOne(
    @Param() param: findOneCat,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    return this.categoriesService.findOne(param, req, res);
  }
  @ApiSecurity("token")
  @UseGuards(AuthGuard)
  @UseGuards(AdminGuard)
  @Put(":uuid")
  async update(
    @Param() param: findOneCat,
    @Req() req: Request,
    @Res() res: Response,
    @Body() body: createCategories,
  ) {
    return this.categoriesService.update(param, req, res, body);
  }
  @ApiSecurity("token")
  @UseGuards(AuthGuard)
  @UseGuards(AdminGuard)
  @Delete(":uuid")
  async delete(
    @Param() param: findOneCat,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    return this.categoriesService.delete(param, req, res);
  }
}
