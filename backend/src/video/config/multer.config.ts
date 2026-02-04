import { diskStorage } from "multer";
import { extname } from "path";

export const multerOptionsForVideo = {
  storage: diskStorage({
    destination: "./uploads/video",
    filename: (req, file, callback) => {
      const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9);
      const ext = extname(file.originalname);
      callback(null, `${uniqueSuffix}${ext}`);
    },
  }),
};
