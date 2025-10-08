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
  ParseUUIDPipe,
} from '@nestjs/common';
import {
  ApiConsumes,
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiParam,
} from '@nestjs/swagger';
import { FileService } from './file.service';
import { FileInterceptor } from '@nestjs/platform-express';
import { CreateFile, UpdateFile, FileResponse } from './file.dto';
import { multerOptionsForFile } from './config/multer.config';

@Controller({ path: 'file', version: '1' })
@ApiTags('File')
export class FileController {
  constructor(private readonly fileService: FileService) {}

  @Post('upload')
  @ApiConsumes('multipart/form-data')
  @ApiOperation({ summary: 'Upload a new file' })
  @ApiResponse({
    status: 201,
    description: 'File uploaded successfully',
    type: FileResponse,
  })
  @UseInterceptors(FileInterceptor('file', multerOptionsForFile))
  async uploadFile(
    @UploadedFile() file: Express.Multer.File,
    @Body() body: CreateFile,
  ) {
    return this.fileService.uploadFile(body.postId, file);
  }

  @Get()
  @ApiOperation({ summary: 'Get all files' })
  @ApiResponse({
    status: 200,
    description: 'List of all files',
    type: [FileResponse],
  })
  async getAllFiles() {
    return this.fileService.getAllFiles();
  }

  @Get(':uuid')
  @ApiOperation({ summary: 'Get file by UUID' })
  @ApiParam({ name: 'uuid', description: 'File UUID' })
  @ApiResponse({ status: 200, description: 'File found', type: FileResponse })
  @ApiResponse({ status: 404, description: 'File not found' })
  async getFileById(@Param('uuid', ParseUUIDPipe) uuid: string) {
    return this.fileService.getFileById(uuid);
  }

  @Get('post/:postId')
  @ApiOperation({ summary: 'Get files by post ID' })
  @ApiParam({ name: 'postId', description: 'Post ID' })
  @ApiResponse({
    status: 200,
    description: 'Files found',
    type: [FileResponse],
  })
  async getFilesByPostId(@Param('postId') postId: string) {
    return this.fileService.getFilesByPostId(postId);
  }

  @Put(':uuid')
  @ApiOperation({ summary: 'Update file completely' })
  @ApiParam({ name: 'uuid', description: 'File UUID' })
  @ApiResponse({
    status: 200,
    description: 'File updated successfully',
    type: FileResponse,
  })
  @ApiResponse({ status: 404, description: 'File not found' })
  async updateFile(
    @Param('uuid', ParseUUIDPipe) uuid: string,
    @Body() updateFileDto: UpdateFile,
  ) {
    return this.fileService.updateFile(uuid, updateFileDto);
  }

  @Patch(':uuid')
  @ApiOperation({ summary: 'Partially update file' })
  @ApiParam({ name: 'uuid', description: 'File UUID' })
  @ApiResponse({
    status: 200,
    description: 'File updated successfully',
    type: FileResponse,
  })
  @ApiResponse({ status: 404, description: 'File not found' })
  async patchFile(
    @Param('uuid', ParseUUIDPipe) uuid: string,
    @Body() updateFileDto: UpdateFile,
  ) {
    return this.fileService.updateFile(uuid, updateFileDto);
  }

  @Delete(':uuid')
  @ApiOperation({ summary: 'Delete file by UUID' })
  @ApiParam({ name: 'uuid', description: 'File UUID' })
  @ApiResponse({ status: 200, description: 'File deleted successfully' })
  @ApiResponse({ status: 404, description: 'File not found' })
  async deleteFile(@Param('uuid', ParseUUIDPipe) uuid: string) {
    return this.fileService.deleteFile(uuid);
  }

  @Delete('post/:postId')
  @ApiOperation({ summary: 'Delete all files by post ID' })
  @ApiParam({ name: 'postId', description: 'Post ID' })
  @ApiResponse({ status: 200, description: 'Files deleted successfully' })
  async deleteFilesByPostId(@Param('postId') postId: string) {
    return this.fileService.deleteFilesByPostId(postId);
  }
}
