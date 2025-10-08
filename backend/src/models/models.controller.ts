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
  UploadedFile,
  UseInterceptors,
} from '@nestjs/common';
import {
  ApiSecurity,
  ApiTags,
  ApiConsumes,
  ApiOperation,
  ApiResponse,
} from '@nestjs/swagger';
import { ModelsService } from './models.service';
import {
  CreateModels,
  FindAllModels,
  findOneModel,
  ModelUUID,
  updateModel,
} from './models.dto';
import { Request, Response } from 'express';
import { AuthGuard } from 'src/guards/auth.gurad';
import { AdminGuard } from 'src/guards/admin.guard';
import { FileInterceptor } from '@nestjs/platform-express';
import { multerOptionsForModel } from 'src/photo/config/multer.config';

@Controller({ path: 'models', version: '1' })
@ApiTags('Models and thier functions')
export class ModelsController {
  constructor(private modelsService: ModelsService) {}

  @ApiSecurity('token')
  @UseGuards(AuthGuard)
  @Get()
  async findAll(
    @Query() query: FindAllModels,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    return this.modelsService.findAll(query, req, res);
  }
  @ApiSecurity('token')
  @UseGuards(AuthGuard)
  @UseGuards(AdminGuard)
  @Post()
  async create(
    @Body() body: CreateModels,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    return this.modelsService.create(body, req, res);
  }
  @ApiSecurity('token')
  @UseGuards(AuthGuard)
  @UseGuards(AdminGuard)
  @Get('faker')
  async createBulk() {
    return this.modelsService.createBulk();
  }
  @ApiSecurity('token')
  @UseGuards(AuthGuard)
  @Get('/:uuid')
  async findOne(
    @Param() param: ModelUUID,
    @Req() req: Request,
    @Res() res: Response,
    @Query() query: findOneModel,
  ) {
    return this.modelsService.findOne(param, req, res, query);
  }
  @ApiSecurity('token')
  @UseGuards(AuthGuard)
  @UseGuards(AdminGuard)
  @Put('/:uuid')
  async update(
    @Param() param: ModelUUID,
    @Body() body: updateModel,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    return this.modelsService.update(param, body, req, res);
  }
  @ApiSecurity('token')
  @UseGuards(AuthGuard)
  @UseGuards(AdminGuard)
  @Delete('/:uuid')
  async delete(
    @Param() param: ModelUUID,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    return this.modelsService.delete(param, req, res);
  }

  @ApiSecurity('token')
  @UseGuards(AuthGuard)
  @UseGuards(AdminGuard)
  @Post('photo/:uuid')
  @UseInterceptors(FileInterceptor('file', multerOptionsForModel))
  @ApiConsumes('multipart/form-data')
  @ApiOperation({ summary: 'Upload photo for model' })
  @ApiResponse({ status: 200, description: 'Photo uploaded successfully' })
  async uploadPhoto(
    @Param() param: ModelUUID,
    @UploadedFile() file: Express.Multer.File,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    return this.modelsService.uploadPhoto(param, file, req, res);
  }

  @ApiSecurity('token')
  @UseGuards(AuthGuard)
  @UseGuards(AdminGuard)
  @Delete('photo/:uuid')
  @ApiOperation({ summary: 'Delete photo for model' })
  @ApiResponse({ status: 200, description: 'Photo deleted successfully' })
  async deletePhoto(
    @Param() param: ModelUUID,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    return this.modelsService.deletePhoto(param, req, res);
  }
}
