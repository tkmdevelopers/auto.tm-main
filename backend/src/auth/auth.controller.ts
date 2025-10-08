import {
  Body,
  Controller,
  Delete,
  Get,
  HttpStatus,
  Param,
  Patch,
  Post,
  Put,
  Req,
  Res,
  UseGuards,
  UploadedFile,
  UseInterceptors,
} from '@nestjs/common';
import {
  ApiResponse,
  ApiSecurity,
  ApiTags,
  ApiConsumes,
  ApiOperation,
} from '@nestjs/swagger';
import { AuthService } from './auth.service';
import {
  CreateUser,
  DeleteOne,
  FindOne,
  firebaseDto,
  LoginUser,
  Update,
  UpdateUser,
} from './auth.dto';
import { Request, Response } from 'express';
import { AuthGuard } from 'src/guards/auth.gurad';
import { RefreshGuard } from 'src/guards/refresh.guard';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { AdminGuard } from 'src/guards/admin.guard';
import { FileInterceptor } from '@nestjs/platform-express';
import { muletrOptionsForUsers } from 'src/photo/config/multer.config';

@Controller({ path: 'auth', version: '1' })
@ApiTags('Auth')
export class AuthController {
  constructor(private authService: AuthService) {}
  @ApiResponse({
    status: HttpStatus.NOT_ACCEPTABLE,
    description: 'Fill all required fields',
    schema: {
      example: {
        response: 'Fill all required fields',
        status: HttpStatus.NOT_ACCEPTABLE,
        message: 'Fill all required fields',
        name: 'HttpException',
      },
    },
  })
  @ApiResponse({
    status: HttpStatus.INTERNAL_SERVER_ERROR,
    description: 'Interval Server Error',
    schema: {
      example: {
        message: 'Interval Server error',
        name: '(Message Depends on Sequelize Configuration',
      },
    },
  })
  @Post('register')
  async create(
    @Body() body: CreateUser,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    return this.authService.create(body, res, req);
  }
  @Post('login')
  async login(
    @Body() body: LoginUser,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    return this.authService.login(body, res, req);
  }
  @UseGuards(AuthGuard)
  @ApiSecurity('token')
  @Put()
  async patch(
    @Body() body: UpdateUser,
    @Res() res: Response,
    @Req() req: Request,
  ) {
    return this.authService.patch(body, req, res);
  }
  @Get('refresh')
  @ApiSecurity('token')
  @UseGuards(RefreshGuard)
  async refresh(@Req() req: Request) {
    return this.authService.refresh(req);
  }

  @Get('/me')
  @UseGuards(AuthGuard)
  @ApiSecurity('token')
  async me(@Req() req: Request, @Res() res: Response) {
    return this.authService.me(req, res);
  }
  @Get('/users')
  @UseGuards(AuthGuard)
  @UseGuards(AdminGuard)
  @ApiSecurity('token')
  async findAll(@Req() req: Request, @Res() res: Response) {
    return this.authService.findAll(req, res);
  }
  @Get('/:uuid')
  @UseGuards(AuthGuard)
  @UseGuards(AdminGuard)
  @ApiSecurity('token')
  async findOne(
    @Param() param: FindOne,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    return this.authService.findOne(param, req, res);
  }
  @Patch('/:uuid')
  @UseGuards(AuthGuard)
  @UseGuards(AdminGuard)
  @ApiSecurity('token')
  async update(
    @Param() param: FindOne,
    @Body() body: Update,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    return this.authService.update(param, body, req, res);
  }
  @Get('/logout')
  @UseGuards(AuthGuard)
  @ApiSecurity('token')
  async logout(@Req() req: Request, @Res() res: Response) {
    return this.authService.logout(req, res);
  }
  @Put('setFirebase')
  @UseGuards(AuthGuard)
  @ApiSecurity('token')
  async setFirebaseToken(
    @Body() body: firebaseDto,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    return this.authService.setFirebase(body, req, res);
  }
  @Delete('/:uuid')
  @UseGuards(AuthGuard)
  @UseGuards(AdminGuard)
  @ApiSecurity('token')
  async delete(
    @Param() param: DeleteOne,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    return this.authService.deleteOne(param, req, res);
  }

  @UseGuards(AuthGuard)
  @ApiSecurity('token')
  @Post('avatar')
  @UseInterceptors(FileInterceptor('file', muletrOptionsForUsers))
  @ApiConsumes('multipart/form-data')
  @ApiOperation({ summary: 'Upload user avatar' })
  @ApiResponse({ status: 200, description: 'Avatar uploaded successfully' })
  async uploadAvatar(
    @UploadedFile() file: Express.Multer.File,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    return this.authService.uploadAvatar(file, req, res);
  }

  @UseGuards(AuthGuard)
  @ApiSecurity('token')
  @Delete('avatar')
  @ApiOperation({ summary: 'Delete user avatar' })
  @ApiResponse({ status: 200, description: 'Avatar deleted successfully' })
  async deleteAvatar(@Req() req: Request, @Res() res: Response) {
    return this.authService.deleteAvatar(req, res);
  }
}
