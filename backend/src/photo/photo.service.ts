import {
  ArgumentsHost,
  BadRequestException,
  HttpException,
  HttpStatus,
  Inject,
  Injectable,
} from "@nestjs/common";
import * as sharp from "sharp";
import * as path from "path";
import * as fs from "fs";
import { promisify } from "util";

const unlinkAsync = promisify(fs.unlink);
import { v4 as uuidv4 } from "uuid";
import { PhotoUUID, UploadDto, uploadFile, UploadUser } from "./photo.dto";
import { Photo } from "./photo.entity";
import { PhotoPosts } from "src/junction/photo_posts";
import { InjectModel } from "@nestjs/sequelize";
import { Request, Response } from "express";
import { PhotoVlog } from "src/junction/photo_vlog";
@Injectable()
export class PhotoService {
  constructor(@Inject("PHOTO_REPOSITORY") private photo: typeof Photo) {}
  async uploadPhoto(
    files: Array<Express.Multer.File>,
    body: PhotoUUID,
    req: Request,
    res: Response,
  ) {
    try {
      console.log("[uploadPhoto] START", {
        uuid: (body as any)?.uuid,
        fileCount: files?.length,
        method: req?.method,
        paths: files?.map((f) => ({
          originalname: f.originalname,
          fieldname: f.fieldname,
        })),
      });
      if (files.length == 0)
        throw new HttpException("Surat Gelenok", HttpStatus.BAD_REQUEST);
      for (const file of files) {
        const uuid = uuidv4();
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
            `${size.name}_${uuid}${path.extname(file.originalname)}`,
          );
          await sharp(originalPath).resize(size.width).toFile(resizedFilePath);

          paths[size.name] = resizedFilePath;
        }

        await this.photo.create({
          uuid: uuid,
          path: paths,
          originalPath,
        });

        await PhotoPosts.create({
          postId: body.uuid,
          photoUuid: uuid,  // Fixed: column name is photoUuid, not uuid
        });
      }

      return res.status(200).json({ message: "OK" });
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
  async deletePhoto(param: PhotoUUID) {
    try {
      const { uuid } = param;

      const photo = await this.photo.findOne({ where: { uuid } });
      if (!photo) {
        return { message: "Photo not found" };
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

      await this.photo.destroy({
        where: {
          uuid,
        },
      });
      await PhotoPosts.destroy({
        where: {
          photoUuid: uuid,  // Fixed: column name is photoUuid, not uuid
        },
      });
      return { message: "OK" };
    } catch (error) {
      console.error("Error deleting photo:", error);
      return { message: "Internal Server Error", error };
    }
  }

  async uploadBan(files: Array<Express.Multer.File>, body: PhotoUUID) {
    try {
      for (const file of files) {
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

        await this.photo.update(
          {
            path: paths,
            originalPath,
          },
          {
            where: {
              bannerId: body.uuid,
            },
          },
        );
      }

      return { message: "OK" };
    } catch (error) {
      console.error("Error uploading banner photos:", error);
      throw new Error("Failed to upload banner photos");
    }
  }
  async deleteBanners(param: PhotoUUID) {
    try {
      const { uuid } = param;

      const photo = await this.photo.findOne({ where: { uuid } });
      if (!photo) {
        return { message: "Photo not found" };
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

      await this.photo.destroy({
        where: {
          uuid,
        },
      });
      return { message: "OK" };
    } catch (error) {
      console.error("Error deleting banner:", error);
      return { message: "Internal Server Error", error };
    }
  }
  async uploadCat(files: Array<Express.Multer.File>, body: PhotoUUID) {
    try {
      for (const file of files) {
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

        await this.photo.update(
          {
            path: paths,
            originalPath,
          },
          {
            where: {
              categoryId: body.uuid,
            },
          },
        );
      }

      return { message: "OK" };
    } catch (error) {
      console.error("Error uploading Category photos:", error);
      throw new Error("Failed to upload banner photos");
    }
  }
  async uploadSubscription(file: Express.Multer.File, body: { uuid: string }) {
    try {
      if (!file || !file.path) {
        throw new BadRequestException("No file uploaded or invalid file path");
      }

      const originalPath = file.path;
      console.log(originalPath);
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
        console.log(`Saving resized file: ${resizedFilePath}`);
        await sharp(originalPath).resize(size.width).toFile(resizedFilePath);
        paths[size.name] = resizedFilePath;
      }

      await this.photo.update(
        { path: paths, originalPath },
        { where: { subscriptionId: body.uuid } },
      );

      return { message: "OK" };
    } catch (error) {
      console.error("Error uploading Category photos:", error);
      throw new Error("Failed to upload banner photos");
    }
  }
  async deleteSubscription(param: PhotoUUID) {
    try {
      const { uuid } = param;

      const photo = await this.photo.findOne({ where: { uuid } });
      if (!photo) {
        return { message: "Photo not found" };
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

      await this.photo.destroy({
        where: {
          uuid,
        },
      });
      return { message: "OK" };
    } catch (error) {
      console.error("Error deleting subscription photo:", error);
      return { message: "Internal Server Error", error };
    }
  }
  async uploadUser(
    file: Express.Multer.File,
    body: UploadUser,
    req: Request | any,
    res: Response,
  ) {
    try {
      const userId = req?.uuid;
      if (!userId) {
        return res.status(400).json({ message: "Missing user context" });
      }
      const originalPath = file.path;
      const uploadDir = path.dirname(originalPath);

      const sizes = [
        { name: "large", width: 1024 },
        { name: "medium", width: 512 },
        { name: "small", width: 256 },
      ];

      const paths: any = { small: "", medium: "", large: "" };
      for (const size of sizes) {
        const resizedFilePath = path.join(
          uploadDir,
          `${size.name}_${uuidv4()}${path.extname(file.originalname)}`,
        );
        await sharp(originalPath).resize(size.width).toFile(resizedFilePath);
        paths[size.name] = resizedFilePath;
      }

      // Try to find an existing user photo row
      const existing = await this.photo.findOne({ where: { userId } });
      if (!existing) {
        const created = await this.photo.create({
          uuid: uuidv4(),
          path: paths,
          originalPath,
          userId,
        } as any);
        return res
          .status(200)
          .json({ message: "OK", paths: created.path, created: true });
      } else {
        await existing.update({ path: paths, originalPath });
        return res
          .status(200)
          .json({ message: "OK", paths: existing.path, updated: true });
      }
    } catch (error) {
      console.error("Error uploading user photo:", error);
      return res.status(500).json({ message: "Upload failed" });
    }
  }
  async deleteUser(param: PhotoUUID) {
    try {
      const { uuid } = param;

      const photo = await this.photo.findOne({ where: { uuid } });
      if (!photo) {
        return { message: "Photo not found" };
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

      await this.photo.destroy({
        where: {
          uuid,
        },
      });
      return { message: "OK" };
    } catch (error) {
      console.error("Error deleting user photo:", error);
      return { message: "Internal Server Error", error };
    }
  }
  async uploadVlog(
    file: Express.Multer.File,
    body: uploadFile,
    req: Request,
    res: Response,
  ) {
    try {
      console.log(file);
      const originalPath = file?.path;
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

      const newPhoto = await this.photo.create({
        uuid: uuidv4(),
        originalPath,
        path: paths,
      });

      return res.status(200).json({ message: "OK", uuid: newPhoto });
    } catch (error) {
      console.error("Error uploading Category photos:", error);
      throw new Error("Failed to upload banner photos");
    }
  }
  async deleteVlog(param: PhotoUUID) {
    try {
      const { uuid } = param;

      const photo = await this.photo.findOne({ where: { uuid } });
      if (!photo) {
        return { message: "Photo not found" };
      }

      const baseDir = path.join(__dirname, "..", "..");

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

      await this.photo.destroy({ where: { uuid } });

      return { message: "OK" };
    } catch (error) {
      console.error("Error deleting vlog:", error);
      return { message: "Internal Server Error", error };
    }
  }
  async uploadBrand(
    file: Express.Multer.File,
    body: uploadFile,
    req: Request,
    res: Response,
  ) {
    try {
      console.log(file);
      const originalPath = file?.path;
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

      const newPhoto = await this.photo.create({
        uuid: uuidv4(),
        originalPath,
        path: paths,
        brandsId: body?.uuid,
      });

      return res.status(200).json({ message: "OK", uuid: newPhoto });
    } catch (error) {
      console.error("Error uploading Category photos:", error);
      throw new Error("Failed to upload banner photos");
    }
  }
  async deleteBrand(param: PhotoUUID) {
    try {
      const { uuid } = param;

      const photo = await this.photo.findOne({ where: { uuid } });
      if (!photo) {
        return { message: "Photo not found" };
      }

      const baseDir = path.join(__dirname, "..", "..");

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

      await this.photo.destroy({ where: { uuid } });

      return { message: "OK" };
    } catch (error) {
      console.error("Error deleting vlog:", error);
      return { message: "Internal Server Error", error };
    }
  }
  async uploadModel(
    file: Express.Multer.File,
    body: uploadFile,
    req: Request,
    res: Response,
  ) {
    try {
      console.log(file);
      const originalPath = file?.path;
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

      const newPhoto = await this.photo.create({
        uuid: uuidv4(),
        originalPath,
        path: paths,
        modelsId: body?.uuid,
      });

      return res.status(200).json({ message: "OK", uuid: newPhoto });
    } catch (error) {
      console.error("Error uploading Category photos:", error);
      throw new Error("Failed to upload banner photos");
    }
  }
  async deleteModel(param: PhotoUUID) {
    try {
      const { uuid } = param;

      const photo = await this.photo.findOne({ where: { uuid } });
      if (!photo) {
        return { message: "Photo not found" };
      }

      const baseDir = path.join(__dirname, "..", "..");

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

      await this.photo.destroy({ where: { uuid } });

      return { message: "OK" };
    } catch (error) {
      console.error("Error deleting vlog:", error);
      return { message: "Internal Server Error", error };
    }
  }
}
