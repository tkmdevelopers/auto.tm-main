import { HttpException, HttpStatus, Inject, Injectable } from "@nestjs/common";
import { createCommets, findAllComments } from "./comments.dto";
import { Request, Response } from "express";
import { AuthenticatedRequest } from "src/utils/types";
import { Posts } from "src/post/post.entity";
import { User } from "src/auth/auth.entity";
import { Photo } from "src/photo/photo.entity";
import { v4 as uuidv4 } from "uuid";
import { Comments } from "./comments.entity";

@Injectable()
export class CommentsService {
  constructor(
    @Inject("POSTS_REPOSITORY") private posts: typeof Posts,
    @Inject("USERS_REPOSITORY") private users: typeof User,
    @Inject("COMMENTS_REPOSITORY") private comments: typeof Comments,
  ) {}

  async findAll(
    body: findAllComments,
    req: AuthenticatedRequest,
    res: Response,
  ) {
    try {
      const { postId } = body;
      const comments = await this.comments.findAll({
        where: { postId },
        order: [["createdAt", "ASC"]],
        group: [
          "Comments.uuid",
          "user.uuid",
          "user->avatar.uuid",
          "parent.uuid",
          "parent->user.uuid",
        ],
        include: [
          {
            model: this.users,
            attributes: ["uuid", "name", "email"],
            include: [
              {
                model: Photo,
                as: "avatar",
                attributes: ["uuid", "path", "originalPath"],
              },
            ],
          },
          {
            model: Comments,
            as: "parent",
            attributes: ["uuid", "sender"],
            include: [
              {
                model: this.users,
                attributes: ["uuid", "name", "email"],
              },
            ],
          },
        ],
      });
      if (!comments) throw new HttpException("Empty", HttpStatus.NOT_FOUND);

      return res.status(200).json(comments);
    } catch (error) {
      if (!error.status) {
        console.log(error);
        return res.status(500).json({
          message: "Internal server error!",
          error: error?.parent?.detail,
        });
      }
      return res.status(error.status).json(error);
    }
  }

  async create(body: createCommets, req: AuthenticatedRequest, res: Response) {
    try {
      const { message, postId, replyTo } = body;

      const user = await this.users.findOne({
        where: { uuid: req?.uuid },
        attributes: ["uuid", "email", "name"],
        include: [
          {
            model: Photo,
            as: "avatar",
            attributes: ["uuid", "path", "originalPath"],
          },
        ],
      });

      const comment = await this.comments.create({
        uuid: uuidv4(),
        message,
        postId,
        userId: req?.uuid,
        sender: user?.name || user?.email,
        replyTo: replyTo || null,
      });

      // Re-fetch with associations to return consistent shape
      const fullComment = await this.comments.findOne({
        where: { uuid: comment.uuid },
        include: [
          {
            model: this.users,
            attributes: ["uuid", "name", "email"],
            include: [
              {
                model: Photo,
                as: "avatar",
                attributes: ["uuid", "path", "originalPath"],
              },
            ],
          },
          {
            model: this.comments,
            as: "parent",
            attributes: ["uuid", "sender"],
            include: [
              {
                model: this.users,
                attributes: ["uuid", "name", "email"],
              },
            ],
          },
        ],
      });
      return res.status(200).json(fullComment);
    } catch (error) {
      if (!error.status) {
        console.log(error);
        return res.status(500).json({
          message: "Internal server error!",
          error: error?.parent?.detail,
        });
      }
      return res.status(error.status).json(error);
    }
  }

  async findOne(id: string, req: AuthenticatedRequest, res: Response) {
    try {
      const comment = await this.comments.findOne({ where: { uuid: id } });
      if (!comment) throw new HttpException("Not found", HttpStatus.NOT_FOUND);
      return res.status(200).json(comment);
    } catch (error) {
      if (!error.status) {
        console.log(error);
        return res.status(500).json({
          message: "Internal server error!",
          error: error?.parent?.detail,
        });
      }
      return res.status(error.status).json(error);
    }
  }

  async update(
    id: string,
    body: any,
    req: AuthenticatedRequest,
    res: Response,
  ) {
    try {
      const comment = await this.comments.findOne({ where: { uuid: id } });
      if (!comment) throw new HttpException("Not found", HttpStatus.NOT_FOUND);

      await this.comments.update(body, { where: { uuid: id } });

      const updated = await this.comments.findOne({ where: { uuid: id } });
      return res.status(200).json(updated);
    } catch (error) {
      if (!error.status) {
        console.log(error);
        return res.status(500).json({
          message: "Internal server error!",
          error: error?.parent?.detail,
        });
      }
      return res.status(error.status).json(error);
    }
  }

  async remove(id: string, req: AuthenticatedRequest, res: Response) {
    try {
      const comment = await this.comments.findOne({ where: { uuid: id } });
      if (!comment) throw new HttpException("Not found", HttpStatus.NOT_FOUND);

      await this.comments.destroy({ where: { uuid: id } });
      return res.status(200).json({ message: "Deleted successfully" });
    } catch (error) {
      if (!error.status) {
        console.log(error);
        return res.status(500).json({
          message: "Internal server error!",
          error: error?.parent?.detail,
        });
      }
      return res.status(error.status).json(error);
    }
  }
}
