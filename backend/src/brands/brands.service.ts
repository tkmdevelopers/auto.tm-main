import { HttpException, HttpStatus, Inject, Injectable } from "@nestjs/common";
import {
  BrandsUUID,
  CreateBrands,
  FindALlBrands,
  FindOneBrands,
  listBrands,
  Search,
  UpdateBrands,
} from "./brands.dto";
import { Request, Response } from "express";
import { Brands } from "./brands.entity";
import { Models } from "src/models/models.entity";
import { Posts } from "src/post/post.entity";
import { createRandomBrands } from "src/utils/fakers/createBrands";
import { stringToBoolean } from "src/utils/functions/stringBool";
import { v4 as uuidv4 } from "uuid";
import { BrandsUser } from "src/junction/brands_user";
import { User } from "src/auth/auth.entity";
import { FindOptions, Op } from "sequelize";
import { Photo } from "src/photo/photo.entity";

@Injectable()
export class BrandsService {
  constructor(
    @Inject("BRANDS_REPOSITORY") private brands: typeof Brands,
    @Inject("MODELS_REPOSITORY") private models: typeof Models,
    @Inject("POSTS_REPOSITORY") private posts: typeof Posts,
    @Inject("USERS_REPOSITORY") private users: typeof User,
    @Inject("PHOTO_REPOSITORY") private photo: typeof Photo,
  ) {}
  async listOfBrands(req, res, body: listBrands) {
    try {
      const { uuids, post } = body;
      const includePayload: {}[] = ["photo"];
      if (post)
        includePayload.push({
          model: this.posts,
          as: "posts",
          include: [
            { model: this.brands, as: "brand", attributes: ["name"] },
            { model: this.models, as: "model", attributes: ["name"] },
          ],
        });
      const payload: FindOptions = {
        where: {
          uuid: {
            [Op.in]: [...uuids],
          },
        },
        attributes: ["uuid", "name"],
        include: [...includePayload],
        order: [["createdAt", "desc"]],
      };

      const brand_res = await this.brands.findAll(payload);
      return res.status(200).json(brand_res);
    } catch (error) {
      if (!error.status) {
        console.log(error);
        return res.status(500).json({ message: "Internal server error!" });
      }
      return res.status(error.status).json(error);
    }
  }
  async subscribe(body: BrandsUUID, req: Request | any, res: Response) {
    try {
      const { uuid } = body;
      if (!uuid) {
        throw new HttpException(
          "Fill all required fields",
          HttpStatus.NOT_ACCEPTABLE,
        );
      }
      const status = await BrandsUser.create({ uuid, userId: req?.uuid });
      if (!status)
        throw new HttpException(
          "Something went wrong",
          HttpStatus.INTERNAL_SERVER_ERROR,
        );
      return res.status(200).json({ message: "Subscribed", uuid: req?.uuid });
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

  async mySubscribes(req: Request | any, res: Response) {
    try {
      const mySubscribes = await this.brands.findAll({
        include: [
          { model: User, where: { uuid: req?.uuid }, attributes: ["uuid"] },
        ],
      });
      return res.status(200).json(mySubscribes);
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

  async unsubscribe(body: BrandsUUID, req: Request | any, res: Response) {
    try {
      const { uuid } = body;
      if (!uuid) {
        throw new HttpException(
          "Fill all required fields",
          HttpStatus.NOT_ACCEPTABLE,
        );
      }
      const status = await BrandsUser.destroy({ where: { uuid } });
      if (!status)
        throw new HttpException(
          "Something went wrong",
          HttpStatus.INTERNAL_SERVER_ERROR,
        );
      return res.status(200).json({ message: "Unubscribed", uuid: req?.uuid });
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
  async findAll(query: FindALlBrands, req: Request | any, res: Response) {
    try {
      const { limit, model, offset, post, search, sortAs, location } = query;
      const includePayload: {}[] = [{ model: this.photo, as: "photo" }];
      const model_bool: boolean = stringToBoolean(model);
      const post_bool: boolean = stringToBoolean(post);
      if (model_bool) includePayload.push({ model: this.models, as: "models" });
      if (post_bool) includePayload.push({ model: this.posts, as: "posts" });
      const brands = await this.brands.findAll({
        limit: limit || 200,
        offset: offset || 0,
        include: [...includePayload],
        order: [["name", sortAs || "asc"]],
        where: {
          [Op.and]: {
            name: {
              [Op.iLike]: `%${search || ""}%`,
            },
            ...(location != null && { location }),
          },
        },
      });
      return res.status(200).json(brands);
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
      const brands_fake: { uuid: string; name: string }[] = [];

      for (let i = 0; i < 10; i++) {
        const brand = createRandomBrands();
        brands_fake.push({ uuid: brand.uuid, name: brand.name });
      }
      await this.brands.bulkCreate(brands_fake);
      return "ok";
    } catch (error) {
      return error;
    }
  }

  async create(body: CreateBrands, req: Request | any, res: Response) {
    try {
      const { name, location } = body;
      if (!name) {
        throw new HttpException(
          "Fill all required fields!",
          HttpStatus.BAD_REQUEST,
        );
      }
      const brands = await this.brands.create({
        uuid: uuidv4(),
        name,
        location,
      });
      return res.status(200).json({
        message: "New Brand successfully created",
        uuid: brands?.uuid,
      });
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
    query: FindOneBrands,
    req: Request | any,
    res: Response,
    param: BrandsUUID,
  ) {
    try {
      const { model, post } = query;
      const { uuid } = param;
      const includePayload: {}[] = [{ model: this.photo, as: "photo" }];
      const model_bool: boolean = stringToBoolean(model);
      const post_bool: boolean = stringToBoolean(post);
      if (model_bool) includePayload.push({ model: this.models, as: "models" });
      if (post_bool) includePayload.push({ model: this.posts, as: "posts" });
      const brand = await this.brands.findOne({
        where: { uuid },
        include: [...includePayload],
      });
      if (!brand)
        throw new HttpException("Brand Not Found", HttpStatus.NOT_FOUND);
      return res.status(200).json(brand);
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
    param: BrandsUUID,
    body: UpdateBrands,
    req: Request | any,
    res: Response,
  ) {
    try {
      const { uuid } = param;
      const { name, location } = body;
      const brand = await this.brands.update(
        { name, location },
        { where: { uuid } },
      );

      if (!brand)
        throw new HttpException("Brand Not Found", HttpStatus.NOT_FOUND);
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

  async delete(param: BrandsUUID, req: Request | any, res: Response) {
    try {
      const { uuid } = param;
      const brand = await this.brands.destroy({ where: { uuid } });
      if (!brand)
        throw new HttpException("Brand Not Found", HttpStatus.NOT_FOUND);
      return res.status(200).json({ message: "Brand Successfully deleted" });
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

  async suggest(query: Search, req: Request | any, res: Response) {
    function normalize(str: string): string {
      return str.replace(/\s+/g, "");
    }
    try {
      const searchTerm = query.search?.trim();
      const limit = query.limit || 10;
      const offset = query.offset || 0;
      console.log(searchTerm);
      if (!searchTerm) {
        return res.status(400).json({ message: "Search query is required" });
      }

      const normalizedSearch = normalize(searchTerm);
      console.log(normalizedSearch);
      const brands = await this.brands.findAll({
        include: [{ model: this.models }],
      });

      const suggestionPool: {
        label: string;
        brand_label: string;
        model_label?: string;
        brand_uuid: string;
        model_uuid?: string;
        compare: string;
      }[] = [];

      for (const brand of brands) {
        suggestionPool.push({
          label: brand.name,
          brand_label: brand.name,
          brand_uuid: brand.uuid,
          compare: normalize(brand.name),
        });

        for (const model of brand.models || []) {
          const combo = `${brand.name} ${model.name}`;

          suggestionPool.push({
            label: combo,
            brand_label: brand.name,
            model_label: model.name,
            brand_uuid: brand.uuid,
            model_uuid: model.uuid,
            compare: normalize(combo),
          });
        }
      }
      const bestMatches = suggestionPool.filter((item) =>
        item.compare.toLowerCase().includes(normalizedSearch.toLowerCase()),
      );

      console.log(bestMatches);

      return res.status(200).json({ results: bestMatches });
    } catch (error) {
      if (!error.status) {
        console.error(error);
        return res.status(500).json({
          message: "Internal server error!",
          error: error?.parent?.detail,
        });
      }
      return res.status(error.status).json(error);
    }
  }
}
