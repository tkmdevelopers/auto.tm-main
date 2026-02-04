import { Inject, Injectable } from "@nestjs/common";
import { Request, Response } from "express";
import { User } from "src/auth/auth.entity";
import { FindOne, updateAdmin } from "./admins.dto";
import { Op } from "sequelize";

@Injectable()
export class AdminsService {
  constructor(@Inject("USERS_REPOSITORY") private Users: typeof User) {}

  // async setAdmin() {
  //   try {
  //     const admin = await this.Users.update(
  //       { role: 'admin', status: true, access: ['admins'] },
  //       { where: { email: 'bagtyyarkowusow.dev@gmail.com' } },
  //     );
  //     return admin;
  //   } catch (error) {
  //     return error;
  //   }
  // }
  async findAll(req: Request, res: Response) {
    try {
      const admins = await this.Users.findAll({
        where: { role: "admin" },
        attributes: { exclude: ["password"] },
      });

      return res.status(200).json(admins);
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
  async findOne(param: FindOne, req: Request, res: Response) {
    try {
      const { uuid } = param;
      const admins = await this.Users.findOne({
        where: { uuid },
        attributes: { exclude: ["password", "refreshToken", "otp"] },
      });
      return res.status(200).json(admins);
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
  async updateAdmin(
    param: FindOne,
    req: Request,
    res: Response,
    body: updateAdmin,
  ) {
    try {
      const { uuid } = param;
      const { access, email, name, password, phone, status } = body;
      const admins = await this.Users.update(
        { access, email, name, phone, status },
        { where: { uuid } },
      );
      return res.status(200).json({ message: "Updated Admin" });
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
