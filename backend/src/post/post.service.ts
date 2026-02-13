import { HttpException, HttpStatus, Inject, Injectable } from "@nestjs/common";
import { Brands } from "src/brands/brands.entity";
import { Models } from "src/models/models.entity";
import { Convert, Posts } from "./post.entity";
import { createRandomPoster } from "src/utils/fakers/createPoster";
import {
  CreatePost,
  FindAllPosts,
  FindOnePost,
  FindOneUUID,
  listPost,
  UpdatePost,
} from "./post.dto";
import { AuthenticatedRequest } from "src/utils/types";
import { stringToBoolean } from "src/utils/functions/stringBool";
import { FindOptions } from "sequelize/types/model";
import { Op } from "sequelize";
import { Photo } from "src/photo/photo.entity";
import { Categories } from "src/categories/categories.entity";
import { v4 as uuidv4 } from "uuid";
import { Comments } from "src/comments/comments.entity";
import { User } from "src/auth/auth.entity";
import { Subscriptions } from "src/subscription/subscription.entity";
import { Video } from "src/video/video.entity";
import { File } from "src/file/file.entity";

@Injectable()
export class PostService {
  constructor(
    @Inject("BRANDS_REPOSITORY") private brands: typeof Brands,
    @Inject("MODELS_REPOSITORY") private models: typeof Models,
    @Inject("POSTS_REPOSITORY") private posts: typeof Posts,
    @Inject("COMMENTS_REPOSITORY") private comments: typeof Comments,
    @Inject("PHOTO_REPOSITORY") private photo: typeof Photo,
    @Inject("VIDEO_REPOSITORY") private video: typeof Video,
    @Inject("CATEGORIES_REPOSITORY") private category: typeof Categories,
    @Inject("SUBSCRIPTIONS_REPOSITORY")
    private subscription: typeof Subscriptions,
    @Inject("USERS_REPOSITORY") private user: typeof User,
    @Inject("FILE_REPOSITORY") private file: typeof File,
  ) {}

  async rate() {
    const usd = await Convert.findOrCreate({
      where: { label: "USD" },
      defaults: { label: "USD", rate: 19.5 },
    });
    const tmt = await Convert.findOrCreate({
      where: { label: "TMT" },
      defaults: { label: "TMT", rate: 1 },
    });
    return { usd: usd[0], tmt: tmt[0] };
  }

  async createBulk() {
    const posts_fake: any[] = [];

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
          region: (model as any)?.personalInfo?.region || "Local",
        },
        description: model.description,
      });
    }
    await this.posts.bulkCreate(posts_fake);
    return { status: "success", count: 10 };
  }

  async count() {
    const count = await this.posts.count();
    return { posts_count: count };
  }

    async findAll(query: FindAllPosts) {
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
        categoryFilter,
        engineType,
        enginePower,
        credit,
        exchange,
        subFilter,
        subscription,
        color,
        maxPrice,
        milleage,
        minPrice,
        transmission,
        maxYear,
        minYear,
        brandFilter,
        modelFilter,
        condition,
        region,
        location,
        countOnly,
      } = query;

      const includePayload: any[] = [];
  
      if (stringToBoolean(brand)) {
        includePayload.push({ model: this.brands, as: "brand" });
      }
      if (subFilter) {
        includePayload.push({
          model: this.subscription,
          as: "subscription",
          where: {
            uuid: {
              [Op.in]: typeof subFilter == "string" ? [subFilter] : [...subFilter],
            },
          },
        });
      }
      if (stringToBoolean(model)) {
        includePayload.push({
          model: this.models,
          as: "model",
        });
      }
      if (stringToBoolean(photo)) {
        includePayload.push({ model: this.photo, as: "photo" });
      }
      if (stringToBoolean(category)) {
        includePayload.push({ model: this.category, as: "category" });
      }
      if (stringToBoolean(subscription)) {
        includePayload.push({
          model: this.subscription,
          as: "subscription",
          attributes: ["uuid", "name"],
          include: ["photo"],
        });
      }
  
      const baseWhere: any = {
        ...(status !== undefined && { status: stringToBoolean(status as any) }),
        ...((minYear != null || maxYear != null) && {
          year: { [Op.between]: [+minYear || 0, +maxYear || 2100] },
        }),
        ...(engineType != null && { engineType }),
        ...(enginePower != null && { enginePower: { [Op.gte]: +enginePower } }),
        ...(credit != null && { credit: stringToBoolean(credit) }),
        ...(exchange != null && { exchange: stringToBoolean(exchange) }),
        ...(milleage != null && { milleage: { [Op.lte]: +milleage } }),
        ...((minPrice != null || maxPrice != null) && {
          price: { [Op.between]: [+minPrice || 0, +maxPrice || 2000000000] },
        }),
        ...(transmission != null && { transmission }),
        ...(condition != null && { condition }),
        ...(brandFilter != null && {
          brandsId: Array.isArray(brandFilter)
            ? { [Op.in]: brandFilter }
            : brandFilter,
        }),
        ...(modelFilter != null && {
          modelsId: Array.isArray(modelFilter)
            ? { [Op.in]: modelFilter }
            : modelFilter,
        }),
        ...(categoryFilter != null && { categoryId: categoryFilter }),
        ...(color != null && {
          color: Array.isArray(color) ? { [Op.in]: color } : color,
        }),
        ...(location != null && { location: { [Op.iLike]: `%${location}%` } }),
        ...(region != null && {
          "personalInfo.region": { [Op.iLike]: `%${region}%` },
        }),
      };
  
      // If search is provided, look into brand and model names via inclusions
      if (search) {
        baseWhere[Op.or] = [
          { description: { [Op.iLike]: `%${search}%` } },
          { "$brand.name$": { [Op.iLike]: `%${search}%` } },
          { "$model.name$": { [Op.iLike]: `%${search}%` } },
        ];
        // Ensure brand and model are included if searching by them
        if (!stringToBoolean(brand)) includePayload.push({ model: this.brands, as: "brand", attributes: ["name"] });
        if (!stringToBoolean(model)) includePayload.push({ model: this.models, as: "model", attributes: ["name"] });
      }

      if (stringToBoolean(countOnly)) {
        const count = await this.posts.count({
          where: { ...baseWhere },
          include: includePayload.filter((inc) => inc.where), // Only include required joins for counting
        });
        return { count };
      }
  
      const payload: FindOptions = {
        limit: limit || 50,
        offset: offset || 0,
        include: [...includePayload],
        order: [[sortBy || "createdAt", sortAs || "desc"]],
        attributes: { exclude: ["userId"] },
        where: { ...baseWhere },
      };
  
      return this.posts.findAndCountAll(payload);
    }

  async listOfProducts(body: listPost) {
    const { brand, model, uuids, photo } = body;
    const includePayload: any[] = [];
    if (stringToBoolean(brand))
      includePayload.push({ model: this.brands, as: "brand" });
    if (stringToBoolean(model))
      includePayload.push({ model: this.models, as: "model" });
    if (stringToBoolean(photo))
      includePayload.push({ model: this.photo, as: "photo" });

    return this.posts.findAll({
      where: {
        uuid: {
          [Op.in]: uuids,
        },
      },
      include: [...includePayload],
      order: [["createdAt", "desc"]],
    });
  }

  async findOne(query: FindOnePost, param: FindOneUUID) {
    const { uuid } = param;
    const { brand, model, photo, subscription } = query;
    const includePayload: any[] = [
      { model: this.video, as: "video" },
      { model: this.file, as: "file" },
    ];

    if (stringToBoolean(brand))
      includePayload.push({ model: this.brands, as: "brand" });
    if (stringToBoolean(subscription))
      includePayload.push({ model: this.subscription, as: "subscription" });
    if (stringToBoolean(model))
      includePayload.push({ model: this.models, as: "model" });
    if (stringToBoolean(photo))
      includePayload.push({ model: this.photo, as: "photo" });

    const post = await this.posts.findOne({
      where: { uuid },
      attributes: { exclude: ["userId"] },
      include: [
        ...includePayload,
        { model: this.comments, as: "comments" },
        { model: this.category, as: "category" },
      ],
    });

    if (!post) throw new HttpException("Post Not Found", HttpStatus.NOT_FOUND);

    // Attach derived publicUrl for video if available
    const postJson: any = post.get({ plain: true });
    if (postJson.video && postJson.video.url) {
      const raw = (postJson.video.url as string).replace(/\\/g, "/");
      const uploadsIndex = raw.lastIndexOf("uploads");
      const relative =
        uploadsIndex !== -1
          ? raw
              .substring(uploadsIndex + "uploads".length)
              .replace(/^[\\/]+/, "")
          : raw;
      postJson.video.url = relative;
      postJson.video.publicUrl = `/media/${relative}`;
    }

    return postJson;
  }

  async create(body: CreatePost, req: AuthenticatedRequest) {
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
      color,
      transmission,
      vin,
      year,
    } = body;

    // ===== INPUT VALIDATION =====
    const numericPrice = Number(price);
    if (isNaN(numericPrice) || numericPrice < 0) {
      throw new HttpException("Invalid price value", HttpStatus.BAD_REQUEST);
    }

    if (brandsId) {
      const brandExists = await this.brands.findOne({
        where: { uuid: brandsId },
      });
      if (!brandExists)
        throw new HttpException("Invalid brand", HttpStatus.BAD_REQUEST);
    }

    if (modelsId) {
      const modelExists = await this.models.findOne({
        where: { uuid: modelsId },
      });
      if (!modelExists)
        throw new HttpException("Invalid model", HttpStatus.BAD_REQUEST);
    }

    const userId = req.uuid;
    if (!userId)
      throw new HttpException("Unauthorized", HttpStatus.UNAUTHORIZED);

    const userExists = await this.user.findOne({ where: { uuid: userId } });
    if (!userExists)
      throw new HttpException("User not found", HttpStatus.NOT_FOUND);

    // ===== CURRENCY CONVERSION =====
    const rate = await Convert.findOne({ where: { label: currency || "TMT" } });
    const conversionRate = rate?.rate ?? 1.0;
    const convertedPrice = Math.ceil(conversionRate * numericPrice);

    const new_post = await this.posts.create({
      uuid: uuidv4(),
      brandsId: brandsId || null,
      location,
      modelsId: modelsId || null,
      condition,
      vin,
      year,
      transmission,
      originalPrice: numericPrice,
      price: convertedPrice,
      subscriptionId: subscriptionId || null,
      color: color || null,
      exchange,
      credit,
      originalCurrency: currency || "TMT",
      personalInfo: {
        name: personalInfo?.name,
        location: personalInfo?.location,
        phone: phone,
        region: personalInfo?.region,
      },
      milleage: Number(milleage) || 0,
      enginePower: Number(enginePower) || 0,
      engineType,
      currency: "TMT",
      description,
      status: null,
      userId,
    });

    return {
      message: "New Post successfully created",
      uuid: new_post.uuid,
    };
  }

  async update(param: FindOneUUID, body: UpdatePost) {
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
      color,
      credit,
      exchange,
      transmission,
      vin,
      subscriptionId,
      status,
      year,
    } = body;

    const [updatedCount] = await this.posts.update(
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
        color,
        transmission,
        vin,
        year,
        subscriptionId,
      },
      { where: { uuid } },
    );

    if (updatedCount === 0)
      throw new HttpException("Post Not Found", HttpStatus.NOT_FOUND);

    return { message: "Successfully changed", uuid };
  }

  async delete(param: FindOneUUID) {
    const { uuid } = param;
    const deletedCount = await this.posts.destroy({ where: { uuid } });
    if (deletedCount === 0)
      throw new HttpException("Post Not Found", HttpStatus.NOT_FOUND);
    return { message: "Post Successfully deleted" };
  }

  async me(req: AuthenticatedRequest) {
    return this.posts.findAll({
      where: { userId: req.uuid },
      include: ["photo", "brand", "model"],
      order: [["createdAt", "DESC"]],
    });
  }
}
