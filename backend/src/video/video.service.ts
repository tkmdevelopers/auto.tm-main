import { Inject, Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/sequelize';
import { Video } from './video.entity';
import { Posts } from 'src/post/post.entity';
import * as ffmpeg from 'fluent-ffmpeg';
import * as path from 'path';
import * as fs from 'fs';
import { UpdateVideo } from './video.dto';

@Injectable()
export class VideoService {
  constructor(
    @Inject('POSTS_REPOSITORY') private postRepo: typeof Posts,
    @Inject('VIDEO_REPOSITORY') private videoRepo: typeof Video,
  ) {}

  async createVideo(uuid: string, inputPath: string) {
    try {
      const proccesPath: any = inputPath;
      const new_video = await this.videoRepo.create({
        url: proccesPath,
        postId: uuid,
      });
      return new_video;
    } catch (error) {
      return error;
    }
  }

  async getAllVideos() {
    return await this.videoRepo.findAll({
      include: [{ model: Posts, as: 'post' }],
    });
  }

  async getVideoById(id: number) {
    const video = await this.videoRepo.findByPk(id, {
      include: [{ model: Posts, as: 'post' }],
    });
    if (!video) {
      throw new NotFoundException(`Video with ID ${id} not found`);
    }
    return video;
  }

  async getVideosByPostId(postId: string) {
    return await this.videoRepo.findAll({
      where: { postId },
      include: [{ model: Posts, as: 'post' }],
    });
  }

  async updateVideo(id: number, updateVideoDto: UpdateVideo) {
    const video = await this.getVideoById(id);
    
    if (updateVideoDto.postId !== undefined) {
      video.postId = updateVideoDto.postId;
    }
    
    return await video.save();
  }

  async deleteVideo(id: number) {
    const video = await this.getVideoById(id);
    
    // Delete the physical video file from the filesystem
    if (video.url) {
      try {
        const videoPath = path.resolve(video.url);
        if (fs.existsSync(videoPath)) {
          fs.unlinkSync(videoPath);
        }
      } catch (error) {
        console.error(`Error deleting video from filesystem: ${error.message}`);
      }
    }
    
    // Delete the database record
    await video.destroy();
    
    return { message: 'Video deleted successfully' };
  }

  async deleteVideosByPostId(postId: string) {
    const videos = await this.getVideosByPostId(postId);
    
    for (const video of videos) {
      await this.deleteVideo(video.id);
    }
    
    return { message: `All videos for post ${postId} deleted successfully` };
  }

  async uploadVideo(postId: string, file: Express.Multer.File) {
    try {
      const newVideo = await this.videoRepo.create({
        url: file.path,
        postId: postId,
      });
      return newVideo;
    } catch (error) {
      throw new Error(`Failed to upload video: ${error.message}`);
    }
  }
}
