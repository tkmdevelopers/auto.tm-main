import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Put,
  Patch,
  UploadedFile,
  UseInterceptors,
  ParseIntPipe,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import {
  ApiBody,
  ApiConsumes,
  ApiParam,
  ApiTags,
  ApiOperation,
  ApiResponse,
} from '@nestjs/swagger';
import { diskStorage } from 'multer';
import { VideoService } from './video.service';
import { UploadDto, CreateVideo, UpdateVideo, VideoResponse } from './video.dto';
import { uploadFile } from 'src/photo/photo.dto';
import { multerOptionsForVideo } from './config/multer.config';

@Controller({ path: 'video', version: '1' })
@ApiTags('Video and Functions')
export class VideoController {
  constructor(private videoService: VideoService) {}

  @Post('upload')
  @UseInterceptors(FileInterceptor('file', multerOptionsForVideo))
  @ApiConsumes('multipart/form-data')
  @ApiOperation({ summary: 'Upload a new video' })
  @ApiResponse({
    status: 201,
    description: 'Video uploaded successfully',
    type: VideoResponse,
  })
  async uploadVideo(
    @UploadedFile() file: Express.Multer.File,
    @Body() body: CreateVideo,
  ) {
    return this.videoService.uploadVideo(body.postId, file);
  }

  @Put()
  @UseInterceptors(FileInterceptor('file', multerOptionsForVideo))
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        file: {
          type: 'string',
          format: 'binary',
        },
        uuid: {
          type: 'string',
        },
      },
    },
  })
  @ApiOperation({ summary: 'Create video with UUID' })
  @ApiResponse({
    status: 200,
    description: 'Video created successfully',
    type: VideoResponse,
  })
  async createVideo(
    @UploadedFile() file: Express.Multer.File,
    @Body() body: uploadFile,
  ) {
    return this.videoService.createVideo(body?.uuid, file.path);
  }

  @Get()
  @ApiOperation({ summary: 'Get all videos' })
  @ApiResponse({
    status: 200,
    description: 'List of all videos',
    type: [VideoResponse],
  })
  async getAllVideos() {
    return this.videoService.getAllVideos();
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get video by ID' })
  @ApiParam({ name: 'id', description: 'Video ID' })
  @ApiResponse({
    status: 200,
    description: 'Video found',
    type: VideoResponse,
  })
  @ApiResponse({ status: 404, description: 'Video not found' })
  async getVideoById(@Param('id', ParseIntPipe) id: number) {
    return this.videoService.getVideoById(id);
  }

  @Get('post/:postId')
  @ApiOperation({ summary: 'Get videos by post ID' })
  @ApiParam({ name: 'postId', description: 'Post ID' })
  @ApiResponse({
    status: 200,
    description: 'Videos found',
    type: [VideoResponse],
  })
  async getVideosByPostId(@Param('postId') postId: string) {
    return this.videoService.getVideosByPostId(postId);
  }

  @Put(':id')
  @ApiOperation({ summary: 'Update video completely' })
  @ApiParam({ name: 'id', description: 'Video ID' })
  @ApiResponse({
    status: 200,
    description: 'Video updated successfully',
    type: VideoResponse,
  })
  @ApiResponse({ status: 404, description: 'Video not found' })
  async updateVideo(
    @Param('id', ParseIntPipe) id: number,
    @Body() updateVideoDto: UpdateVideo,
  ) {
    return this.videoService.updateVideo(id, updateVideoDto);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Partially update video' })
  @ApiParam({ name: 'id', description: 'Video ID' })
  @ApiResponse({
    status: 200,
    description: 'Video updated successfully',
    type: VideoResponse,
  })
  @ApiResponse({ status: 404, description: 'Video not found' })
  async patchVideo(
    @Param('id', ParseIntPipe) id: number,
    @Body() updateVideoDto: UpdateVideo,
  ) {
    return this.videoService.updateVideo(id, updateVideoDto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete video by ID' })
  @ApiParam({ name: 'id', description: 'Video ID' })
  @ApiResponse({ status: 200, description: 'Video deleted successfully' })
  @ApiResponse({ status: 404, description: 'Video not found' })
  async deleteVideo(@Param('id', ParseIntPipe) id: number) {
    return this.videoService.deleteVideo(id);
  }

  @Delete('post/:postId')
  @ApiOperation({ summary: 'Delete all videos by post ID' })
  @ApiParam({ name: 'postId', description: 'Post ID' })
  @ApiResponse({ status: 200, description: 'Videos deleted successfully' })
  async deleteVideosByPostId(@Param('postId') postId: string) {
    return this.videoService.deleteVideosByPostId(postId);
  }
}
