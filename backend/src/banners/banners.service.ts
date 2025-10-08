import { Inject, Injectable } from '@nestjs/common';
import { Request, Response } from 'express';
import { BannerUUID, FindAllBanners } from './banners.dto';
import { FindOptions } from 'sequelize/types/model';
import { Banners } from './banners.entity';
import { Photo } from 'src/photo/photo.entity';
import { User } from 'src/auth/auth.entity';
import { v4 as uuidv4 } from 'uuid';
@Injectable()
export class BannersService {
  constructor(
    @Inject('BANNERS_REPOSITORY') private banners: typeof Banners,
    @Inject('PHOTO_REPOSITORY') private photo: typeof Photo,
  ) {}
  async findAll(res: Response, req: Request, query: FindAllBanners) {
    let { limit, offset } = query;
    try {
      const object: FindOptions = {
        limit: limit || 50,
        offset: offset || 0,
        include: ['photo'],
      };

      const banners = await this.banners.findAll(object);
      return res.status(200).json(banners);
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
  async create(req: Request | any, res: Response) {
    try {
      const uuid = uuidv4();
      const creator = await User.findOne({
        where: { uuid: req.uuid },
        attributes: ['name', 'email'],
      });

      const banner = await this.banners.create({
        uuid,
        creator: {
          name: creator?.name,
          email: creator?.email,
        },
      });
      await this.photo.create({
        uuid: uuidv4(),
        bannerId: uuid,
      });

      return res.status(200).json({ message: 'ok', uuid: banner?.uuid });
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
  async deleteBanner(res: Response, req: any, param: BannerUUID) {
    try {
      const { uuid } = param;
      await this.banners
        .destroy({
          where: { uuid: uuid },
        })
        .then((response) => {
          return res.status(200).json({
            message: 'ok',
          });
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
  async getOne(res: Response, req: any, param: BannerUUID) {
    try {
      const { uuid } = param;
      const banner = await this.banners.findOne({
        where: { uuid: uuid },
        include: ['photo'],
      });
      return res.status(200).json(banner);
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
