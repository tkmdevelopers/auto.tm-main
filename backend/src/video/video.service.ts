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
      const normalizedInput = inputPath.replace(/\\/g, '/');
      const uploadsIndex = normalizedInput.lastIndexOf('uploads');
      const relative = uploadsIndex !== -1
        ? normalizedInput.substring(uploadsIndex + 'uploads'.length).replace(/^[\\/]+/, '')
        : normalizedInput;
      const new_video = await this.videoRepo.create({
        url: relative,
        postId: uuid,
      });
      return { ...new_video.toJSON(), publicUrl: `/media/${relative}` };
    } catch (error) {
      return error;
    }
  }

  async getAllVideos() {
    const videos = await this.videoRepo.findAll({
      include: [{ model: Posts, as: 'post' }],
    });
    return videos.map(v => {
      const plain: any = v.toJSON();
      if (plain.url) {
        plain.url = plain.url.replace(/\\/g, '/');
        plain.publicUrl = `/media/${plain.url.replace(/^[\\/]+/, '')}`;
      }
      return plain;
    });
  }

  async getVideoById(id: number) {
    const video = await this.videoRepo.findByPk(id, {
      include: [{ model: Posts, as: 'post' }],
    });
    if (!video) {
      throw new NotFoundException(`Video with ID ${id} not found`);
    }
    const plain: any = video.toJSON();
    if (plain.url) {
      plain.url = plain.url.replace(/\\/g, '/');
      plain.publicUrl = `/media/${plain.url.replace(/^[\\/]+/, '')}`;
    }
    return plain;
  }

  async getVideosByPostId(postId: string) {
    const list = await this.videoRepo.findAll({
      where: { postId },
      include: [{ model: Posts, as: 'post' }],
    });
    return list.map(v => {
      const plain: any = v.toJSON();
      if (plain.url) {
        plain.url = plain.url.replace(/\\/g, '/');
        plain.publicUrl = `/media/${plain.url.replace(/^[\\/]+/, '')}`;
      }
      return plain;
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
      // Validate video duration before accepting upload
      const duration = await this.getVideoDuration(file.path);
      const maxDurationSeconds = 60;
      
      if (duration > maxDurationSeconds) {
        // Delete the uploaded file since it's invalid
        if (fs.existsSync(file.path)) {
          fs.unlinkSync(file.path);
        }
        throw new Error(`Video duration (${Math.round(duration)}s) exceeds maximum allowed duration (${maxDurationSeconds}s)`);
      }
      
      const normalizedPath = file.path.replace(/\\/g, '/');
      const uploadsIndex = normalizedPath.lastIndexOf('uploads');
      const relative = uploadsIndex !== -1
        ? normalizedPath.substring(uploadsIndex + 'uploads'.length).replace(/^[\\/]+/, '')
        : normalizedPath;
      const newVideo = await this.videoRepo.create({
        url: relative,
        postId: postId,
      });
      return { ...newVideo.toJSON(), publicUrl: `/media/${relative}` };
    } catch (error) {
      throw new Error(`Failed to upload video: ${error.message}`);
    }
  }

  private async getVideoDuration(filePath: string): Promise<number> {
    return new Promise((resolve, reject) => {
      ffmpeg.ffprobe(filePath, (err, metadata) => {
        if (err) {
          reject(err);
          return;
        }
        const duration = metadata.format.duration || 0;
        resolve(duration);
      });
    });
  }
}
