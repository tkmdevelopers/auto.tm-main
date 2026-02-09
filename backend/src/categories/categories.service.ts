import { HttpException, HttpStatus, Inject, Injectable } from "@nestjs/common";
import { Categories } from "./categories.entity";
import { Photo } from "src/photo/photo.entity";
import {
  createCategories,
  findAllCategories,
  findOneCat,
} from "./categories.dto";
import { Request, Response } from "express";
import { AuthenticatedRequest } from "src/utils/types";
import { stringToBoolean } from "src/utils/functions/stringBool";
import { Posts } from "src/post/post.entity";
import { v4 as uuidv4 } from "uuid";
import { User } from "src/auth/auth.entity";
@Injectable()
export class CategoriesService {
  constructor(
    @Inject("CATEGORIES_REPOSITORY") private Category: typeof Categories,
    @Inject("PHOTO_REPOSITORY")
    private photo: typeof Photo,
    @Inject("POSTS_REPOSITORY") private posts: typeof Posts,
  ) {}

  async findAll(
    query: findAllCategories,
    req: AuthenticatedRequest,
    res: Response,
  ) {
    try {
      const { limit, offset, post, search, sort, photo } = query;
      const includePayload: {}[] = [];
      const post_bool: boolean = stringToBoolean(post);
      const photo_bool: boolean = stringToBoolean(photo);
      if (post_bool) includePayload.push({ model: this.posts, as: "posts" });
      if (photo_bool) includePayload.push({ model: this.photo, as: "photo" });
      const categoryies = await this.Category.findAll({
        limit: limit || 50,
        offset: offset || 0,
        include: [...includePayload],
        order: [["priority", sort || "asc"]],
      });
      return res.status(200).json(categoryies);
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

  async create(
    body: createCategories,
    req: AuthenticatedRequest,
    res: Response,
  ) {
    try {
      const uuid = uuidv4();
      const creator = await User.findOne({
        where: { uuid: req.uuid },
        attributes: ["name", "email"],
      });

      const category = await this.Category.create({
        uuid,
        creator: {
          name: creator?.name,
          email: creator?.email,
        },
        name: {
          tm: body?.name?.tm,
          ru: body?.name?.ru,
          en: body?.name?.en,
        },
        priority: body?.priority,
      });
      await this.photo.create({
        uuid: uuidv4(),
        categoryId: uuid,
      });

      return res.status(200).json({ message: "ok", uuid: category?.uuid });
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
  async findOne(param: findOneCat, req: AuthenticatedRequest, res: Response) {
    try {
      const { uuid } = param;

      const categoryies = await this.Category.findOne({
        where: { uuid },
        include: ["photo"],
        order: [["priority", "asc"]],
      });
      return res.status(200).json(categoryies);
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
    param: findOneCat,
    req: AuthenticatedRequest,
    res: Response,
    body: createCategories,
  ) {
    try {
      const { uuid } = param;
      const { name, priority } = body;
      const categoryies = await this.Category.update(
        { name, priority },
        {
          where: { uuid },
        },
      );
      return res.status(200).json({ message: "Updated" });
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
  async delete(param: findOneCat, req: AuthenticatedRequest, res: Response) {
    try {
      const { uuid } = param;
      const categoryies = await this.Category.destroy({
        where: { uuid },
      });
      return res.status(200).json({ message: "Deleted" });
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
