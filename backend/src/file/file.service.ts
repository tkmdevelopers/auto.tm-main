import { Inject, Injectable, NotFoundException } from '@nestjs/common';
import { File } from './file.entity';
import { v4 as uuidv4 } from 'uuid';
import * as fs from 'fs';
import * as path from 'path';
import { UpdateFile } from './file.dto';

@Injectable()
export class FileService {
  constructor(
    @Inject('FILE_REPOSITORY')
    private fileRepository: typeof File,
  ) {}

  async uploadFile(postId: string, file: Express.Multer.File) {
    const new_file = await this.fileRepository.findOne({
      where: {
        postId: postId,
      },
    });
    if (new_file) {
      return new_file;
    }
    const newFile = await this.fileRepository.create({
      path: file.path,
      uuid: uuidv4(),
      postId: postId,
    });
    return newFile;
  }

  async getAllFiles() {
    return await this.fileRepository.findAll();
  }

  async getFileById(uuid: string) {
    const file = await this.fileRepository.findByPk(uuid);
    if (!file) {
      throw new NotFoundException(`File with UUID ${uuid} not found`);
    }
    return file;
  }

  async getFilesByPostId(postId: string) {
    return await this.fileRepository.findAll({
      where: { postId },
    });
  }

  async updateFile(uuid: string, updateFileDto: UpdateFile) {
    const file = await this.getFileById(uuid);

    if (updateFileDto.postId !== undefined) {
      file.postId = updateFileDto.postId;
    }

    return await file.save();
  }

  async deleteFile(uuid: string) {
    const file = await this.getFileById(uuid);

    // Delete the physical file from the filesystem
    if (file.path) {
      try {
        const filePath = path.resolve(file.path);
        if (fs.existsSync(filePath)) {
          fs.unlinkSync(filePath);
        }
      } catch (error) {
        console.error(`Error deleting file from filesystem: ${error.message}`);
      }
    }

    // Delete the database record
    await file.destroy();

    return { message: 'File deleted successfully' };
  }

  async deleteFilesByPostId(postId: string) {
    const files = await this.getFilesByPostId(postId);

    for (const file of files) {
      await this.deleteFile(file.uuid);
    }

    return { message: `All files for post ${postId} deleted successfully` };
  }
}
