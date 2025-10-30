import { diskStorage } from 'multer';
import { extname } from 'path';
import { BadRequestException } from '@nestjs/common';

export const multerOptionsForVideo = {
  storage: diskStorage({
    destination: './uploads/video',
    filename: (req, file, callback) => {
      const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
      const ext = extname(file.originalname);
      callback(null, `${uniqueSuffix}${ext}`);
    },
  }),
  limits: {
    fileSize: 100 * 1024 * 1024, // 100 MB max file size
  },
  fileFilter: (req, file, callback) => {
    // Accept video files only
    const allowedMimeTypes = [
      'video/mp4',
      'video/mpeg',
      'video/quicktime',
      'video/x-msvideo',
      'video/x-matroska',
      'video/webm',
    ];
    
    if (allowedMimeTypes.includes(file.mimetype)) {
      callback(null, true);
    } else {
      callback(
        new BadRequestException(
          `Invalid file type. Only video files are allowed. Received: ${file.mimetype}`
        ),
        false,
      );
    }
  },
};
