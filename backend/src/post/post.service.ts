import { HttpException, HttpStatus, Inject, Injectable } from '@nestjs/common';
import { Brands } from 'src/brands/brands.entity';
import { Models } from 'src/models/models.entity';
import { createRandomModels } from 'src/utils/fakers/createModels';
import { Convert, Posts } from './post.entity';
import { createRandomPoster } from 'src/utils/fakers/createPoster';
import {
  CreatePost,
  FindAllPosts,
  FindOnePost,
  FindOneUUID,
  listPost,
  UpdatePost,
} from './post.dto';
import { Request, Response } from 'express';
import { stringToBoolean } from 'src/utils/functions/stringBool';
import { FindOptions } from 'sequelize/types/model';
import { and, Op, where } from 'sequelize';
import { Photo } from 'src/photo/photo.entity';
import { Categories } from 'src/categories/categories.entity';
import { v4 as uuidv4 } from 'uuid';
import { Comments } from 'src/comments/comments.entity';
import { User } from 'src/auth/auth.entity';
import { Subscriptions } from 'src/subscription/subscription.entity';
import { Video } from 'src/video/video.entity';
import { File } from 'src/file/file.entity';
@Injectable()
export class PostService {
  constructor(
    @Inject('BRANDS_REPOSITORY') private brands: typeof Brands,
    @Inject('MODELS_REPOSITORY') private models: typeof Models,
    @Inject('POSTS_REPOSITORY') private posts: typeof Posts,
    @Inject('COMMENTS_REPOSITORY') private comments: typeof Comments,
    @Inject('PHOTO_REPOSITORY') private photo: typeof Photo,
    @Inject('VIDEO_REPOSITORY') private video: typeof Video,
    @Inject('CATEGORIES_REPOSITORY') private category: typeof Categories,
    @Inject('SUBSCRIPTIONS_REPOSITORY')
    private subscription: typeof Subscriptions,
    @Inject('USERS_REPOSITORY') private user: typeof User,
    @Inject('FILE_REPOSITORY') private file: typeof File,
  ) {}
  async rate(req: Request, res: Response) {
    try {
      const usd = await Convert.create({
        label: 'USD',
        rate: 19.5,
      });
      const tmt = await Convert.create({
        label: 'TMT',
        rate: 1,
      });
      return res.json({ usd, tmt });
    } catch (error) {}
  }
  async createBulk() {
    try {
      const posts_fake: {
        uuid: string;
        brandsId: string;
        modelsId: string;
        condition: string;
        engineType: string;
        transmission: string;
        enginePower: number;
        year: number;
        milleage: number;
        vin: string;
        price: number;
        currency: string;
        personalInfo: { name: string; location: string; region?: string };
        description: string;
      }[] = [];

      for (let i = 0; i < 10; i++) {
        const model = createRandomPoster();

        posts_fake.push({
          uuid: model.uuid,
          brandsId: model?.brandsId,
          modelsId: model?.modelsId,
          condition: model?.condition,
          engineType: model?.engineType,
          transmission: model.transmission,
          enginePower: model?.enginePower,
          year: model?.year,
          milleage: model.milleage,
          vin: model.vin,
          price: model.price,
          currency: model.currency,
          personalInfo: {
            name: model?.personalInfo?.name,
            location: model?.personalInfo?.location,
            region: (model as any)?.personalInfo?.region || 'Local',
          },
          description: model.description,
        });
      }
      await this.posts.bulkCreate(posts_fake);
      return 'ok';
    } catch (error) {
      return error;
    }
  }
  async count(req: Request, res: Response) {
    try {
      const posts_count = await this.posts.count();
      console.log(posts_count);
      return res?.status(200).json({ posts_count });
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
  async findAll(query: FindAllPosts, req: Request, res: Response) {
    try {
      const {
        brand,
        limit,
        model,
        offset,
        status,
        search,
        sortAs,
        photo,
        sortBy,
        category,
        enginePower,
        engineType,
        location,
        subFilter,
        subscription,
        maxPrice,
        milleage,
        minPrice,
        transmission,
        maxYear,
        minYear,
        brandFilter,
        modelFilter,
        condition,
      } = query;
      const includePayload: any[] = [];

      if (stringToBoolean(brand)) {
        includePayload.push({ model: this.brands, as: 'brand' });
      }
      if (subFilter) {
        includePayload.push({
          model: this.subscription,
          as: 'subscription',
          where: {
            uuid: {
              [Op.in]:
                typeof subFilter == 'string' ? [subFilter] : [...subFilter],
            },
          },
        });
      }
      if (stringToBoolean(model)) {
        includePayload.push({
          model: this.models,
          as: 'model',
          ...(search
            ? {
                where: {
                  name: {
                    [Op.iLike]: `%${search}%`,
                  },
                },
                required: true,
              }
            : {}),
        });
      }
      if (stringToBoolean(photo)) {
        includePayload.push({ model: this.photo, as: 'photo' });
      }
      if (stringToBoolean(category)) {
        includePayload.push({ model: this.category, as: 'category' });
      }
      if (stringToBoolean(subscription)) {
        includePayload.push({
          model: this.subscription,
          as: 'subscription',
          attributes: ['uuid', 'name'],
          include: ['photo'],
        });
      }

      const baseWhere: any = {
        ...(status !== undefined && { status }),
        ...((minYear != null || maxYear != null) && {
          year: { [Op.between]: [+minYear || 0, +maxYear || 2100] },
        }),
        ...(engineType != null && { engineType }),
        ...(milleage != null && { milleage: { [Op.lte]: milleage } }),
        ...((minPrice != null || maxPrice != null) && {
          price: { [Op.between]: [+minPrice || 0, +maxPrice || 1000000] },
        }),
        ...(transmission != null && { transmission }),
        ...(condition != null && { condition }),
        ...(brandFilter != null && { brandsId: brandFilter }),
        ...(modelFilter != null && { modelsId: modelFilter }),
      };

      const payload: FindOptions = {
        limit: limit || 50,
        offset: offset || 0,
        include: [...includePayload],
        order: [[sortBy || 'createdAt', sortAs || 'desc']],
        attributes: { exclude: ['userId'] },
        where: { ...baseWhere },
      };

      const posts = await this.posts.findAll(payload);
      return res.status(200).json(posts);
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
  async listOfProducts(req, res, body: listPost) {
    try {
      const { brand, model, uuids, photo } = body;
      const includePayload: {}[] = [];
      const brand_bool: boolean = stringToBoolean(brand);
      const model_bool: boolean = stringToBoolean(model);
      const photo_bool: boolean = stringToBoolean(photo);
      if (brand_bool) includePayload.push({ model: this.brands, as: 'brand' });
      if (model_bool) includePayload.push({ model: this.models, as: 'model' });
      if (photo_bool) includePayload.push({ model: this.photo, as: 'photo' });
      const payload: FindOptions = {
        where: {
          uuid: {
            [Op.in]: [...uuids],
          },
        },
        include: [...includePayload],
        order: [['createdAt', 'desc']],
      };

      const post_res = await this.posts.findAll(payload);
      return res.status(200).json(post_res);
    } catch (error) {
      if (!error.status) {
        console.log(error);
        return res.status(500).json({ message: 'Internal server error!' });
      }
      return res.status(error.status).json(error);
    }
  }

  async findOne(
    query: FindOnePost,
    req: Request,
    res: Response,
    param: FindOneUUID,
  ) {
    try {
      const { uuid } = param;
      const { brand, model, photo, subscription } = query;
      const includePayload: {}[] = [
        {
          model: this.video,
          as: 'video',
        },
        {
          model: this.file,
          as: 'file',
        },
      ];
      const brand_bool: boolean = stringToBoolean(brand);
      const model_bool: boolean = stringToBoolean(model);
      const photo_bool: boolean = stringToBoolean(photo);
      const sunbscription_bool: boolean = stringToBoolean(subscription);
      if (brand_bool) includePayload.push({ model: this.brands, as: 'brand' });
      if (sunbscription_bool)
        includePayload.push({ model: this.subscription, as: 'subscription' });
      if (model_bool) includePayload.push({ model: this.models, as: 'model' });
      if (photo_bool) includePayload.push({ model: this.photo, as: 'photo' });
      const payload: FindOptions = {
        where: {
          uuid,
        },
        attributes: { exclude: ['userId'] },
        include: [
          ...includePayload,
          { model: this.comments, as: 'comments' },
          { model: this.category, as: 'category' },
        ],
      };
      const post = await this.posts.findOne(payload);
      // Attach derived publicUrl for video if available
      if (post && (post as any).video) {
        const vid: any = (post as any).video;
        if (vid.url) {
          const raw = (vid.url as string).replace(/\\/g, '/');
          const uploadsIndex = raw.lastIndexOf('uploads');
          const relative = uploadsIndex !== -1 ? raw.substring(uploadsIndex + 'uploads'.length).replace(/^[\\/]+/, '') : raw;
          vid.url = relative;
          vid.publicUrl = `/media/${relative}`;
        }
      }
      return res.status(200).json(post);
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

  async create(body: CreatePost, req: Request | any, res: Response) {
    try {
      const {
        brandsId,
        condition,
        currency,
        description,
        credit,
        exchange,
        enginePower,
        subscriptionId,
        location,
        engineType,
        phone,
        milleage,
        modelsId,
        personalInfo,
        price,
        transmission,
        vin,
        year,
      } = body;
      const rate: any = await Convert.findOne({ where: { label: currency } });
      const covertedCurrency = 'TMT';
      const convertedPrice = Math.ceil(rate?.rate * price);
      const new_post = await this.posts.create({
        uuid: uuidv4(),
        brandsId,
        location,
        modelsId,
        condition,
        vin,
        year,
        transmission,
        originalPrice: Number(price),
        price: Number(convertedPrice),
        subscriptionId,
        exchange,
        credit,
        originalCurrency: currency,
        personalInfo: {
          name: personalInfo?.name,
          location: personalInfo?.location,
          phone: phone,
          region: (personalInfo as any)?.region,
        },
        milleage: milleage,
        enginePower: enginePower,
        engineType,
        currency: 'TMT',
        description,
        status: null,
        userId: req?.uuid,
      });
      return res.status(200).json({
        message: 'New Post successfully created',
        uuid: new_post?.uuid,
      });
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

  async update(
    param: FindOneUUID,
    body: UpdatePost,
    req: Request | any,
    res: Response,
  ) {
    try {
      const { uuid } = param;
      const {
        brandsId,
        condition,
        currency,
        description,
        enginePower,
        engineType,
        milleage,
        modelsId,
        personalInfo,
        price,
        credit,
        exchange,
        transmission,
        vin,
        subscriptionId,
        status,
        year,
      } = body;

      const model = await this.posts.update(
        {
          brandsId,
          condition,
          currency,
          description,
          enginePower,
          engineType,
          milleage,
          modelsId,
          personalInfo,
          price,
          credit,
          exchange,
          status,
          transmission,
          vin,
          year,
          subscriptionId,
        },
        { where: { uuid } },
      );

      if (!model)
        throw new HttpException('Post Not Found', HttpStatus.NOT_FOUND);
      return res
        .status(200)
        .json({ message: 'Successfully changed', uuid: uuid });
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
  async delete(param: FindOneUUID, req: Request | any, res: Response) {
    try {
      const { uuid } = param;
      const post = await this.posts.destroy({ where: { uuid } });
      if (!post)
        throw new HttpException('Model Not Found', HttpStatus.NOT_FOUND);
      return res.status(200).json({ message: 'Post Successfully deleted' });
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

  async me(req: Request | any, res: Response) {
    try {
      const posts = await this.posts.findAll({
        where: { userId: req?.uuid },
        include: ['photo', 'brand', 'model'],
        order: [['createdAt', 'DESC']], // Newest first
      });
      if (!posts) throw new HttpException('Empty', HttpStatus.NOT_FOUND);
      return res.status(200).json(posts);
    } catch (error) {
      if (!error.status) {
        console.log(error);
        return res.status(500).json({ message: 'Internal server error!' });
      }
      return res.status(error.status).json(error);
    }
  }
}
