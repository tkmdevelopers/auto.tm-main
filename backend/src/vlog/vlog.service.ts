import { Injectable, Inject, HttpException, HttpStatus } from "@nestjs/common";
import { Request, Response } from "express";
import { AuthenticatedRequest } from "src/utils/types";
import { Vlogs } from "./vlog.entity";
import { v4 as uuidv4 } from "uuid";
import { CreateVlogDto, FindAllVlogDto, UpdateVlogDto } from "./vlog.dto";
import { Op } from "sequelize";
import { User } from "src/auth/auth.entity";

@Injectable()
export class VlogService {
  constructor(@Inject("VLOG_REPOSITORY") private vlogRepo: typeof Vlogs) {}

  async create(body: CreateVlogDto, req: AuthenticatedRequest, res: Response) {
    try {
      const vlog = await this.vlogRepo.create({
        uuid: uuidv4(),
        title: body.title,
        userId: body.userId || req?.uuid,
        description: body.description || "",
        tag: body.tag || "",
        videoUrl: body.videoUrl || "",
        isActive: body.isActive || false,
        thumbnail: body.thumbnail || {},
        status: "Pending",
        declineMessage: null,
      });

      return res.status(201).json(vlog);
    } catch (error) {
      console.log(error);
      return res.status(500).json({
        message: "Internal server error!",
        error: error?.parent?.detail,
      });
    }
  }

  async findAll(query: FindAllVlogDto, req: AuthenticatedRequest, res: Response) {
    try {
      const {
        userId,
        status,
        search,
        sortBy = "createdAt",
        sortOrder = "DESC",
        page = 1,
        limit = 10,
      } = query;

      const where: any = {};

      if (status) {
        where.status = status;
      }

      if (search) {
        where.title = {
          [Op.iLike]: `%${search}%`,
        };
      }

      const offset = (page - 1) * limit;

      const vlogs = await this.vlogRepo.findAndCountAll({
        where,
        order: [[sortBy, sortOrder]],
        offset,
        include: [{ model: User, include: ["avatar"] }],
        limit,
      });

      return res.status(200).json({
        total: vlogs.count,
        page,
        limit,
        data: vlogs.rows,
      });
    } catch (error) {
      console.log(error);
      return res.status(500).json({
        message: "Internal server error!",
        error: error?.parent?.detail,
      });
    }
  }

  async findOne(id: string, req: AuthenticatedRequest, res: Response) {
    try {
      const vlog = await this.vlogRepo.findOne({ where: { uuid: id } });
      if (!vlog) throw new HttpException("Not found", HttpStatus.NOT_FOUND);

      return res.status(200).json(vlog);
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
    body: UpdateVlogDto,
    req: AuthenticatedRequest,
    res: Response,
  ) {
    try {
      const vlog = await this.vlogRepo.findOne({ where: { uuid: id } });
      if (!vlog) throw new HttpException("Not found", HttpStatus.NOT_FOUND);

      const updateData: any = {};
      if (body.title !== undefined) updateData.title = body.title;
      if (body.description !== undefined)
        updateData.description = body.description;
      if (body.tag !== undefined) updateData.tag = body.tag;
      if (body.videoUrl !== undefined) updateData.videoUrl = body.videoUrl;
      if (body.isActive !== undefined) updateData.isActive = body.isActive;
      if (body.thumbnail !== undefined) updateData.thumbnail = body.thumbnail;

      await this.vlogRepo.update(updateData, { where: { uuid: id } });

      const updated = await this.vlogRepo.findOne({ where: { uuid: id } });
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
      const vlog = await this.vlogRepo.findOne({ where: { uuid: id } });
      if (!vlog) throw new HttpException("Not found", HttpStatus.NOT_FOUND);

      await this.vlogRepo.destroy({ where: { uuid: id } });
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
