import { HttpException, HttpStatus, Inject, Injectable } from "@nestjs/common";
import { Brands } from "src/brands/brands.entity";
import { Posts } from "src/post/post.entity";
import { createRandomModels } from "src/utils/fakers/createModels";
import { Models } from "./models.entity";
import {
  CreateModels,
  FindAllModels,
  findOneModel,
  ModelUUID,
  updateModel,
} from "./models.dto";
import { stringToBoolean } from "src/utils/functions/stringBool";
import { Request, Response } from "express";
import { v4 as uuidv4 } from "uuid";
import { FindOptions } from "sequelize/types/model";
import { Op } from "sequelize";
import { Photo } from "src/photo/photo.entity";
import * as sharp from "sharp";
import * as path from "path";
import * as fs from "fs";
import { promisify } from "util";

const unlinkAsync = promisify(fs.unlink);

@Injectable()
export class ModelsService {
  constructor(
    @Inject("BRANDS_REPOSITORY") private brands: typeof Brands,
    @Inject("MODELS_REPOSITORY") private models: typeof Models,
    @Inject("POSTS_REPOSITORY") private posts: typeof Posts,
    @Inject("PHOTO_REPOSITORY") private photo: typeof Photo,
  ) {}

  async findAll(query: FindAllModels, req: Request | any, res: Response) {
    try {
      const { limit, brand, offset, post, search, sortAs, filter } = query;
      const includePayload: {}[] = [];
      const brand_bool: boolean = stringToBoolean(brand);
      const post_bool: boolean = stringToBoolean(post);
      if (brand_bool) includePayload.push({ model: this.brands, as: "brand" });
      if (post_bool) includePayload.push({ model: this.posts, as: "posts" });
      const payload: FindOptions = {
        limit: limit || 500,
        offset: offset || 0,
        include: [...includePayload, "photo"],
        order: [["name", sortAs || "asc"]],
        where: {
          name: {
            [Op.iLike]: `%${search || ""}%`,
          },
        },
      };
      if (filter) {
        payload["where"] = { brandId: filter };
      }
      const models = await this.models.findAll(payload);
      return res.status(200).json(models);
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

  async createBulk() {
    try {
      const models_fake: { uuid: string; name: string }[] = [];

      for (let i = 0; i < 10; i++) {
        const model = createRandomModels();
        models_fake.push({ uuid: model.uuid, name: model.name });
      }
      await this.models.bulkCreate(models_fake);
      return "ok";
    } catch (error) {
      return error;
    }
  }

  async create(body: CreateModels, req: Request | any, res: Response) {
    try {
      const { name, brandId } = body;
      if (!name) {
        throw new HttpException(
          "Fill all required fields!",
          HttpStatus.BAD_REQUEST,
        );
      }
      const model = await this.models.create({
        uuid: uuidv4(),
        name,
        brandId,
      });
      return res
        .status(200)
        .json({ message: "New Model successfully created", uuid: model?.uuid });
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

  async findOne(
    param: ModelUUID,
    req: Request | any,
    res: Response,
    query: findOneModel,
  ) {
    try {
      const { brand, post } = query;
      const { uuid } = param;
      const includePayload: {}[] = [];
      const brand_bool: boolean = stringToBoolean(brand);
      const post_bool: boolean = stringToBoolean(post);
      if (brand_bool) includePayload.push({ model: this.brands, as: "brand" });
      if (post_bool) includePayload.push({ model: this.posts, as: "posts" });
      const model = await this.models.findOne({
        where: { uuid },
        include: [...includePayload, "photo"],
      });
      if (!model)
        throw new HttpException("Model Not Found", HttpStatus.NOT_FOUND);
      return res.status(200).json(model);
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
    param: ModelUUID,
    body: updateModel,
    req: Request | any,
    res: Response,
  ) {
    try {
      const { uuid } = param;
      const { name, brandId } = body;
      const model = await this.models.update(
        { name, brandId },
        { where: { uuid } },
      );

      if (!model)
        throw new HttpException("Model Not Found", HttpStatus.NOT_FOUND);
      return res
        .status(200)
        .json({ message: "Successfully changed", uuid: uuid });
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
  async delete(param: ModelUUID, req: Request | any, res: Response) {
    try {
      const { uuid } = param;
      const model = await this.models.destroy({ where: { uuid } });
      if (!model)
        throw new HttpException("Model Not Found", HttpStatus.NOT_FOUND);
      return res.status(200).json({ message: "Model Successfully deleted" });
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

  async uploadPhoto(
    param: ModelUUID,
    file: Express.Multer.File,
    req: Request | any,
    res: Response,
  ) {
    try {
      const { uuid } = param;

      // Check if model exists
      const model = await this.models.findOne({ where: { uuid } });
      if (!model) {
        throw new HttpException("Model Not Found", HttpStatus.NOT_FOUND);
      }

      const originalPath = file.path;
      const uploadDir = path.dirname(originalPath);

      const sizes = [
        { name: "large", width: 1024 },
        { name: "medium", width: 512 },
        { name: "small", width: 256 },
      ];

      const paths = {
        small: "",
        medium: "",
        large: "",
      };

      for (const size of sizes) {
        const resizedFilePath = path.join(
          uploadDir,
          `${size.name}_${uuidv4()}${path.extname(file.originalname)}`,
        );
        await sharp(originalPath).resize(size.width).toFile(resizedFilePath);
        paths[size.name] = resizedFilePath;
      }

      // Create or update photo record
      const [photo, created] = await this.photo.findOrCreate({
        where: { modelsId: uuid },
        defaults: {
          uuid: uuidv4(),
          originalPath,
          path: paths,
          modelsId: uuid,
        },
      });

      if (!created) {
        // Update existing photo
        await photo.update({
          originalPath,
          path: paths,
        });
      }

      return res.status(200).json({
        message: "Photo uploaded successfully",
        uuid: photo.uuid,
      });
    } catch (error) {
      console.error("Error uploading model photo:", error);
      return res.status(500).json({
        message: "Internal server error!",
        error: error?.message,
      });
    }
  }

  async deletePhoto(param: ModelUUID, req: Request | any, res: Response) {
    try {
      const { uuid } = param;

      const photo = await this.photo.findOne({ where: { modelsId: uuid } });
      if (!photo) {
        return res.status(404).json({ message: "Photo not found" });
      }

      const baseDir = path.join(__dirname, "..", "..");

      // Delete all resized versions and original file
      for (const size of ["small", "medium", "large"]) {
        const filePath = path.join(baseDir, photo.path?.[size]);
        try {
          if (fs.existsSync(filePath)) {
            await unlinkAsync(filePath);
          }
        } catch (fsError) {
          console.warn(`Failed to delete ${size} file:`, fsError.message);
        }
      }

      // Delete original file if exists
      if (photo.originalPath) {
        const originalFilePath = path.join(baseDir, photo.originalPath);
        try {
          if (fs.existsSync(originalFilePath)) {
            await unlinkAsync(originalFilePath);
          }
        } catch (fsError) {
          console.warn(`Failed to delete original file:`, fsError.message);
        }
      }

      await photo.destroy();

      return res.status(200).json({ message: "Photo deleted successfully" });
    } catch (error) {
      console.error("Error deleting model photo:", error);
      return res.status(500).json({
        message: "Internal server error!",
        error: error?.message,
      });
    }
  }
}
