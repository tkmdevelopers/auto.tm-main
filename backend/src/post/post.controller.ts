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
} from '@nestjs/common';
import { ApiSecurity, ApiTags } from '@nestjs/swagger';
import { PostService } from './post.service';
import {
  CreatePost,
  FindAllPosts,
  FindOnePost,
  FindOneUUID,
  listPost,
  UpdatePost,
} from './post.dto';
import { Response, Request } from 'express';
import { AuthGuard } from 'src/guards/auth.gurad';

@Controller({
  path: 'posts',
  version: '1',
})
@ApiTags('Posts and their functions')
export class PostController {
  constructor(private postService: PostService) {}
  // @ApiSecurity('token')
  // @UseGuards(AuthGuard)
  // Public: allow unauthenticated users to fetch / filter posts
  @Get()
  async findAll(
    @Query() query: FindAllPosts,
    @Res() res: Response,
    @Req() req: Request,
  ) {
    return this.postService.findAll(query, req, res);
  }

  @ApiSecurity('token')
  @UseGuards(AuthGuard)
  @Get('/me')
  async postMe(@Req() req: Request, @Res() res: Response) {
    return this.postService.me(req, res);
  }
  // @ApiSecurity('token')
  // @UseGuards(AuthGuard)
  @Get('/add_rate')
  async add_rate(@Req() req: Request, @Res() res: Response) {
    return this.postService.rate(req, res);
  }
  @ApiSecurity('token')
  @UseGuards(AuthGuard)
  @Post()
  async createPost(
    @Body() body: CreatePost,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    return this.postService.create(body, req, res);
  }
  @Get('/:uuid')
  async findOne(
    @Query() query: FindOnePost,
    @Res() res: Response,
    @Req() req: Request,
    @Param() param: FindOneUUID,
  ) {
    return this.postService.findOne(query, req, res, param);
  }
  @ApiSecurity('token')
  @UseGuards(AuthGuard)
  @Get('faker')
  async createBulk() {
    return this.postService.createBulk();
  }
  // @ApiSecurity('token')
  // @UseGuards(AuthGuard)
  @Post('list')
  listOfProducts(
    @Req() req: any,
    @Res() res: Response,
    @Body() body: listPost,
  ) {
    return this.postService.listOfProducts(req, res, body);
  }
  @ApiSecurity('token')
  @UseGuards(AuthGuard)
  @Put('/:uuid')
  async update(
    @Param() param: FindOneUUID,
    @Body() body: UpdatePost,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    return this.postService.update(param, body, req, res);
  }
  @ApiSecurity('token')
  @UseGuards(AuthGuard)
  @Delete('/:uuid')
  async delete(
    @Param() param: FindOneUUID,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    return this.postService.delete(param, req, res);
  }
  @ApiSecurity('token')
  @UseGuards(AuthGuard)
  @Get('count')
  async count(@Req() req: Request, @Res() res: Response) {
    return this.postService.count(req, res);
  }
}
