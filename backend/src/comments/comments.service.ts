import { HttpException, HttpStatus, Inject, Injectable } from '@nestjs/common';
import { createCommets, findAllComments } from './comments.dto';
import { Request, Response } from 'express';
import { Posts } from 'src/post/post.entity';
import { User } from 'src/auth/auth.entity';
import { v4 as uuidv4 } from 'uuid';
import { Comments } from './comments.entity';

@Injectable()
export class CommentsService {
  constructor(
    @Inject('POSTS_REPOSITORY') private posts: typeof Posts,
    @Inject('USERS_REPOSITORY') private users: typeof User,
    @Inject('COMMENTS_REPOSITORY') private comments: typeof Comments,
  ) {}

  async findAll(body: findAllComments, req: Request | any, res: Response) {
    try {
      const { postId } = body;
      const comments = await this.comments.findAll({
        where: { postId },
      });
      if (!comments) throw new HttpException('Empty', HttpStatus.NOT_FOUND);

      return res.status(200).json(comments);
    } catch (error) {
      if (!error.status) {
        console.log(error);
        return res.status(500).json({
          message: 'Internal server error!',
          error: error?.parent?.detail,
        });
      }
      return res.status(error.status).json(error);
    }
  }

  async create(body: createCommets, req: Request | any, res: Response) {
    try {
      const { message, postId } = body;

      const user = await this.users.findOne({
        where: { uuid: req?.uuid },
        attributes: ['email', 'name'],
      });

      const comment = await this.comments.create({
        uuid: uuidv4(),
        message,
        postId,
        userId: req?.uuid,
        sender: user?.name || user?.email,
      });

      return res.status(200).json(comment);
    } catch (error) {
      if (!error.status) {
        console.log(error);
        return res.status(500).json({
          message: 'Internal server error!',
          error: error?.parent?.detail,
        });
      }
      return res.status(error.status).json(error);
    }
  }

  async findOne(id: string, req: Request | any, res: Response) {
    try {
      const comment = await this.comments.findOne({ where: { uuid: id } });
      if (!comment) throw new HttpException('Not found', HttpStatus.NOT_FOUND);
      return res.status(200).json(comment);
    } catch (error) {
      if (!error.status) {
        console.log(error);
        return res.status(500).json({
          message: 'Internal server error!',
          error: error?.parent?.detail,
        });
      }
      return res.status(error.status).json(error);
    }
  }

  async update(id: string, body: any, req: Request | any, res: Response) {
    try {
      const comment = await this.comments.findOne({ where: { uuid: id } });
      if (!comment) throw new HttpException('Not found', HttpStatus.NOT_FOUND);

      await this.comments.update(body, { where: { uuid: id } });

      const updated = await this.comments.findOne({ where: { uuid: id } });
      return res.status(200).json(updated);
    } catch (error) {
      if (!error.status) {
        console.log(error);
        return res.status(500).json({
          message: 'Internal server error!',
          error: error?.parent?.detail,
        });
      }
      return res.status(error.status).json(error);
    }
  }

  async remove(id: string, req: Request | any, res: Response) {
    try {
      const comment = await this.comments.findOne({ where: { uuid: id } });
      if (!comment) throw new HttpException('Not found', HttpStatus.NOT_FOUND);

      await this.comments.destroy({ where: { uuid: id } });
      return res.status(200).json({ message: 'Deleted successfully' });
    } catch (error) {
      if (!error.status) {
        console.log(error);
        return res.status(500).json({
          message: 'Internal server error!',
          error: error?.parent?.detail,
        });
      }
      return res.status(error.status).json(error);
    }
  }
}
