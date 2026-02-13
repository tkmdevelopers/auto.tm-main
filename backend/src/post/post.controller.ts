import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Post,
  Put,
  Query,
  Req,
  UseGuards,
} from "@nestjs/common";
import {
  ApiOperation,
  ApiResponse,
  ApiSecurity,
  ApiTags,
} from "@nestjs/swagger";
import { PostService } from "./post.service";
import {
  CreatePost,
  FindAllPosts,
  FindOnePost,
  FindOneUUID,
  listPost,
  UpdatePost,
} from "./post.dto";
import { AuthenticatedRequest } from "src/utils/types";
import { AuthGuard } from "src/guards/auth.guard";
import { Posts } from "./post.entity";

@Controller({
  path: "posts",
  version: "1",
})
@ApiTags("Posts")
export class PostController {
  constructor(private postService: PostService) {}

  @Get()
  @ApiOperation({ summary: "Get all posts with filters" })
  @ApiResponse({ status: HttpStatus.OK, type: [Posts] })
  async findAll(@Query() query: FindAllPosts) {
    return this.postService.findAll(query);
  }

  @ApiSecurity("token")
  @UseGuards(AuthGuard)
  @Get("/me")
  @ApiOperation({ summary: "Get current user's posts" })
  @ApiResponse({ status: HttpStatus.OK, type: [Posts] })
  async postMe(@Req() req: AuthenticatedRequest) {
    return this.postService.me(req);
  }

  @Get("/add_rate")
  @ApiOperation({ summary: "Get currency conversion rates" })
  async add_rate() {
    return this.postService.rate();
  }

  @ApiSecurity("token")
  @UseGuards(AuthGuard)
  @Post()
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: "Create a new car listing" })
  @ApiResponse({ status: HttpStatus.CREATED, description: "Post created" })
  async createPost(@Body() body: CreatePost, @Req() req: AuthenticatedRequest) {
    return this.postService.create(body, req);
  }

  @ApiSecurity("token")
  @UseGuards(AuthGuard)
  @Get("count")
  @ApiOperation({ summary: "Get total post count" })
  async count() {
    return this.postService.count();
  }

  @Get("/:uuid")
  @ApiOperation({ summary: "Get post details by UUID" })
  @ApiResponse({ status: HttpStatus.OK, type: Posts })
  async findOne(@Param() param: FindOneUUID, @Query() query: FindOnePost) {
    return this.postService.findOne(query, param);
  }

  @ApiSecurity("token")
  @UseGuards(AuthGuard)
  @Get("faker")
  @ApiOperation({ summary: "Bulk create fake posts (Admin)" })
  async createBulk() {
    return this.postService.createBulk();
  }

  @Post("list")
  @ApiOperation({ summary: "Get list of posts by UUIDs" })
  @ApiResponse({ status: HttpStatus.OK, type: [Posts] })
  async listOfProducts(@Body() body: listPost) {
    return this.postService.listOfProducts(body);
  }

  @ApiSecurity("token")
  @UseGuards(AuthGuard)
  @Put("/:uuid")
  @ApiOperation({ summary: "Update an existing post" })
  async update(@Param() param: FindOneUUID, @Body() body: UpdatePost) {
    return this.postService.update(param, body);
  }

  @ApiSecurity("token")
  @UseGuards(AuthGuard)
  @Delete("/:uuid")
  @ApiOperation({ summary: "Delete a post" })
  async delete(@Param() param: FindOneUUID) {
    return this.postService.delete(param);
  }
}
