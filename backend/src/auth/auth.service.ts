import { HttpException, HttpStatus, Inject, Injectable } from '@nestjs/common';
import {
  CreateUser,
  DeleteOne,
  FindOne,
  firebaseDto,
  LoginUser,
  Update,
  UpdateUser,
} from './auth.dto';
import { Request, Response } from 'express';
import { User } from './auth.entity';
import { v4 as uuidv4 } from 'uuid';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcryptjs';
import { Photo } from 'src/photo/photo.entity';
import * as sharp from 'sharp';
import * as path from 'path';
import * as fs from 'fs';
import { promisify } from 'util';

const unlinkAsync = promisify(fs.unlink);

@Injectable()
export class AuthService {
  constructor(
    @Inject('USERS_REPOSITORY') private Users: typeof User,
    @Inject('PHOTO_REPOSITORY') private photo: typeof Photo,
    private configService: ConfigService,
    private jwtService: JwtService,
  ) {}
  async create(body: CreateUser, res: Response, req: Request) {
    try {
      let { phone } = body;
      if (!phone) {
        throw new HttpException(
          'Fill all required fields',
          HttpStatus.NOT_ACCEPTABLE,
        );
      }
      phone = `+${phone}`;
      const new_user = await this.Users.findOrCreate({
        where: { phone },
        defaults: { uuid: uuidv4(), phone },
      });
      console.log(new_user);
      await this.photo.create({
        uuid: uuidv4(),
        userId: new_user?.[0]?.uuid,
      });
      return res.status(HttpStatus.OK).json({
        message: `New user Successfully created.`,
      });
    } catch (error) {
      if (!error.status) {
        console.log(error);
        return res.status(500).json({
          message: 'Internal server error!',
          detail: error?.parent?.detail || 'Unknown',
        });
      }
      return res.status(error.status).json(error);
    }
  }

  async refresh(req: any): Promise<any> {
    try {
      const user = await this.Users.findOne({
        where: { uuid: req?.uuid },
        attributes: ['uuid', 'refreshToken'],
      });

      const refreshToken = req
        .get('authorization')
        .replace('Bearer', '')
        .trim();

      if (user?.refreshToken == refreshToken) {
        const [accessToken] = await Promise.all([
          this.jwtService.signAsync(
            { uuid: user?.uuid },
            {
              secret: this.configService.get<string>('ACCESS_TOKEN_SECRET_KEY'),
              expiresIn: '24h',
            },
          ),
        ]);
        return { accessToken };
      }
    } catch (error) {
      console.log(error);
    }
  }
  async patch(body: UpdateUser, req: Request | any, res: Response) {
    try {
      const { location, email, name, phone, password } = body;
      console.log(password);
      const salt = !password ? password : await bcrypt.hashSync(password, 10);
      const updatedUser = await this.Users.update(
        { location, email, name, phone, password: salt },
        { where: { uuid: req?.uuid } },
      );
      if (updatedUser) {
        return res.status(HttpStatus.OK).json({
          message: 'Successfully changed',
          uuid: req?.uuid,
        });
      }
    } catch (error) {
      if (!error.status) {
        console.log(error);
        return res.status(500).json({
          message: 'Internal server error!',
          detail: error?.parent?.detail || 'Unknown',
        });
      }
      return res.status(error.status).json(error);
    }
  }

  async uploadAvatar(
    file: Express.Multer.File,
    req: Request | any,
    res: Response,
  ) {
    try {
      const userId = req?.uuid;

      // Check if user exists
      const user = await this.Users.findOne({ where: { uuid: userId } });
      if (!user) {
        throw new HttpException('User Not Found', HttpStatus.NOT_FOUND);
      }

      const originalPath = file.path;
      const uploadDir = path.dirname(originalPath);

      const sizes = [
        { name: 'large', width: 1024 },
        { name: 'medium', width: 512 },
        { name: 'small', width: 256 },
      ];

      const paths = {
        small: '',
        medium: '',
        large: '',
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
        where: { userId },
        defaults: {
          uuid: uuidv4(),
          originalPath,
          path: paths,
          userId,
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
        message: 'Avatar uploaded successfully',
        uuid: photo.uuid,
      });
    } catch (error) {
      console.error('Error uploading avatar:', error);
      return res.status(500).json({
        message: 'Internal server error!',
        error: error?.message,
      });
    }
  }

  async deleteAvatar(req: Request | any, res: Response) {
    try {
      const userId = req?.uuid;

      const photo = await this.photo.findOne({ where: { userId } });
      if (!photo) {
        return res.status(404).json({ message: 'Avatar not found' });
      }

      const baseDir = path.join(__dirname, '..', '..');

      // Delete all resized versions and original file
      for (const size of ['small', 'medium', 'large']) {
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

      return res.status(200).json({ message: 'Avatar deleted successfully' });
    } catch (error) {
      console.error('Error deleting avatar:', error);
      return res.status(500).json({
        message: 'Internal server error!',
        error: error?.message,
      });
    }
  }

  async login(body: LoginUser, res: Response, req: Request | any) {
    try {
      const { email, password } = body;
      if (!email || !password) {
        throw new HttpException(
          'Fill all required fields',
          HttpStatus.NOT_ACCEPTABLE,
        );
      }
      const user = await this.Users.findOne({
        where: { email },
        include: ['avatar'],
      });
      if (!user) {
        throw new HttpException('User Not Found', HttpStatus.NOT_FOUND);
      }
      const isPasswordValid = await bcrypt.compare(password, user.password);
      if (!isPasswordValid) {
        throw new HttpException('Invalid password', HttpStatus.UNAUTHORIZED);
      }
      const [accessToken, refreshToken] = await Promise.all([
        this.jwtService.signAsync(
          { uuid: user?.uuid },
          {
            secret: this.configService.get<string>('ACCESS_TOKEN_SECRET_KEY'),
            expiresIn: '24h',
          },
        ),
        this.jwtService.signAsync(
          { uuid: user?.uuid },
          {
            secret: this.configService.get<string>('REFRESH_TOKEN_SECRET_KEY'),
            expiresIn: '7d',
          },
        ),
      ]);
      await this.Users.update(
        { refreshToken },
        { where: { uuid: user?.uuid } },
      );
      return res.status(HttpStatus.OK).json({
        message: 'Successfully logged in',
        accessToken,
        refreshToken,
        user: {
          uuid: user.uuid,
          name: user.name,
          email: user.email,
          phone: user.phone,
          role: user.role,
          avatar: user.avatar,
        },
      });
    } catch (error) {
      if (!error.status) {
        console.log(error);
        return res.status(500).json({
          message: 'Internal server error!',
          detail: error?.parent?.detail || 'Unknown',
        });
      }
      return res.status(error.status).json(error);
    }
  }

  async me(req: Request | any, res: Response) {
    try {
      const user = await this.Users.findOne({
        where: { uuid: req?.uuid },
        include: ['avatar'],
      });
      if (!user) {
        throw new HttpException('User Not Found', HttpStatus.NOT_FOUND);
      }
      return res.status(HttpStatus.OK).json({
        uuid: user.uuid,
        name: user.name,
        email: user.email,
        phone: user.phone,
        access: user.access,
        role: user.role,
        avatar: user.avatar,
      });
    } catch (error) {
      if (!error.status) {
        console.log(error);
        return res.status(500).json({
          message: 'Internal server error!',
          detail: error?.parent?.detail || 'Unknown',
        });
      }
      return res.status(error.status).json(error);
    }
  }

  async findAll(req: Request | any, res: Response) {
    try {
      const users = await this.Users.findAll({
        include: ['avatar'],
      });
      console.log(users);
      return res.status(HttpStatus.OK).json(users);
    } catch (error) {
      if (!error.status) {
        console.log(error);
        return res.status(500).json({
          message: 'Internal server error!',
          detail: error?.parent?.detail || 'Unknown',
        });
      }
      return res.status(error.status).json(error);
    }
  }

  async findOne(param: FindOne, req: Request | any, res: Response) {
    try {
      const { uuid } = param;
      const user = await this.Users.findOne({
        where: { uuid },
        include: ['avatar'],
      });
      if (!user) {
        throw new HttpException('User Not Found', HttpStatus.NOT_FOUND);
      }
      return res.status(HttpStatus.OK).json(user);
    } catch (error) {
      if (!error.status) {
        console.log(error);
        return res.status(500).json({
          message: 'Internal server error!',
          detail: error?.parent?.detail || 'Unknown',
        });
      }
      return res.status(error.status).json(error);
    }
  }

  async logout(req: Request | any, res: Response) {
    try {
      await this.Users.update(
        { refreshToken: null },
        { where: { uuid: req?.uuid } },
      );
      return res.status(HttpStatus.OK).json({
        message: 'Successfully logged out',
      });
    } catch (error) {
      if (!error.status) {
        console.log(error);
        return res.status(500).json({
          message: 'Internal server error!',
          detail: error?.parent?.detail || 'Unknown',
        });
      }
      return res.status(error.status).json(error);
    }
  }

  async deleteOne(param: DeleteOne, req: Request | any, res: Response) {
    try {
      const { uuid } = param;
      const user = await this.Users.destroy({ where: { uuid } });
      if (!user) {
        throw new HttpException('User Not Found', HttpStatus.NOT_FOUND);
      }
      return res.status(HttpStatus.OK).json({
        message: 'User Successfully deleted',
      });
    } catch (error) {
      if (!error.status) {
        console.log(error);
        return res.status(500).json({
          message: 'Internal server error!',
          detail: error?.parent?.detail || 'Unknown',
        });
      }
      return res.status(error.status).json(error);
    }
  }

  async setFirebase(body: firebaseDto, req: Request | any, res: Response) {
    try {
      const { token } = body;
      await this.Users.update(
        { firebaseToken: token },
        { where: { uuid: req?.uuid } },
      );
      return res.status(HttpStatus.OK).json({
        message: 'Firebase token set successfully',
      });
    } catch (error) {
      if (!error.status) {
        console.log(error);
        return res.status(500).json({
          message: 'Internal server error!',
          detail: error?.parent?.detail || 'Unknown',
        });
      }
      return res.status(error.status).json(error);
    }
  }

  async update(
    param: FindOne,
    body: Update,
    req: Request | any,
    res: Response,
  ) {
    try {
      const { uuid } = param;
      const { location, name, password, access, role } = body;
      const salt = !password ? password : await bcrypt.hashSync(password, 10);
      const updatedUser = await this.Users.update(
        { location, name, password: salt, access, role },
        { where: { uuid } },
      );
      if (updatedUser) {
        return res.status(HttpStatus.OK).json({
          message: 'Successfully changed',
          uuid: uuid,
        });
      }
    } catch (error) {
      if (!error.status) {
        console.log(error);
        return res.status(500).json({
          message: 'Internal server error!',
          detail: error?.parent?.detail || 'Unknown',
        });
      }
      return res.status(error.status).json(error);
    }
  }
}
