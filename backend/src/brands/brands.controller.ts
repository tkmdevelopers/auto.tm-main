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
import { BrandsService } from "./brands.service";
import { ApiSecurity, ApiTags } from "@nestjs/swagger";
import {
  BrandsUUID,
  CreateBrands,
  FindALlBrands,
  FindOneBrands,
  listBrands,
  Search,
  UpdateBrands,
} from "./brands.dto";
import { Request, Response } from "express";
import { AuthGuard } from "src/guards/auth.gurad";
import { AdminGuard } from "src/guards/admin.guard";

@Controller({ path: "brands", version: "1" })
@ApiTags("Brands and their functions")
export class BrandsController {
  constructor(private brandsService: BrandsService) {}
  @Post("list")
  listOfBrands(
    @Req() req: any,
    @Res() res: Response,
    @Body() body: listBrands,
  ) {
    return this.brandsService.listOfBrands(req, res, body);
  }
  @Get()
  async findAll(
    @Query() query: FindALlBrands,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    return this.brandsService.findAll(query, req, res);
  }
  @ApiSecurity("token")
  @UseGuards(AuthGuard)
  @UseGuards(AdminGuard)
  @Post()
  async create(
    @Body() body: CreateBrands,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    return this.brandsService.create(body, req, res);
  }
  @Get("/search")
  async search(
    @Query() query: Search,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    return this.brandsService.suggest(query, req, res);
  }
  @ApiSecurity("token")
  @UseGuards(AuthGuard)
  @Get("/:uuid")
  async findOne(
    @Query() query: FindOneBrands,
    @Req() req: Request,
    @Res() res: Response,
    @Param() param: BrandsUUID,
  ) {
    return this.brandsService.findOne(query, req, res, param);
  }
  @ApiSecurity("token")
  @UseGuards(AuthGuard)
  @UseGuards(AdminGuard)
  @Get("faker")
  async fake_brands() {
    return this.brandsService.createBulk();
  }
  @ApiSecurity("token")
  @UseGuards(AuthGuard)
  @UseGuards(AdminGuard)
  @Put("/:uuid")
  async update(
    @Param() param: BrandsUUID,
    @Body() body: UpdateBrands,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    return this.brandsService.update(param, body, req, res);
  }

  @ApiSecurity("token")
  @UseGuards(AuthGuard)
  @UseGuards(AdminGuard)
  @Delete("/:uuid")
  async delete(
    @Param() param: BrandsUUID,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    return this.brandsService.delete(param, req, res);
  }
  @ApiSecurity("token")
  @UseGuards(AuthGuard)
  @Post("/subscribe")
  async subscribe(
    @Body() body: BrandsUUID,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    return this.brandsService.subscribe(body, req, res);
  }

  @ApiSecurity("token")
  @UseGuards(AuthGuard)
  @Post("/subscribe")
  async mySubscribes(@Req() req: Request, @Res() res: Response) {
    return this.brandsService.mySubscribes(req, res);
  }

  @ApiSecurity("token")
  @UseGuards(AuthGuard)
  @Post("/unsubscribe")
  async unsubscribe(
    @Body() body: BrandsUUID,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    return this.brandsService.unsubscribe(body, req, res);
  }
}
