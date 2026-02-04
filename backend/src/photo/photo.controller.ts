import {
  Body,
  Controller,
  Delete,
  Param,
  Post,
  Put,
  Req,
  Res,
  UploadedFile,
  UploadedFiles,
  UseGuards,
  UseInterceptors,
} from "@nestjs/common";
import {
  ApiConsumes,
  ApiOperation,
  ApiResponse,
  ApiSecurity,
  ApiTags,
} from "@nestjs/swagger";
import { PhotoService } from "./photo.service";
import { FileInterceptor, FilesInterceptor } from "@nestjs/platform-express";
import { PhotoUUID, UploadDto, uploadFile, UploadUser } from "./photo.dto";
import {
  muletrOptionsForUsers,
  multerOptionForVlog,
  multerOptionsForBan,
  multerOptionsForBrand,
  multerOptionsForCat,
  multerOptionsForModel,
  multerOptionsForProducts,
  multerOptionsForSubscription,
} from "./config/multer.config";
import { AuthGuard } from "src/guards/auth.gurad";
import { AdminGuard } from "src/guards/admin.guard";
import { Request, Response } from "express";

@Controller({
  path: "photo",
  version: "1",
})
export class PhotoController {
  constructor(private PhotoService: PhotoService) {}

  @ApiTags("Posts and their functions")
  @ApiSecurity("token")
  @UseGuards(AuthGuard)
  @Put("posts")
  @UseInterceptors(
    FilesInterceptor("files", undefined, multerOptionsForProducts),
  )
  @ApiOperation({ summary: "Upload a file" })
  @ApiConsumes("multipart/form-data")
  uploadFilePhoto(
    @UploadedFiles() files: Express.Multer.File[],
    @Body() body: UploadDto,
    @Res() res: Response,
    @Req() req: Request,
  ) {
    return this.PhotoService.uploadPhoto(files, body, req, res);
  }
  // Added to support frontend sending POST /photo/posts with single field name 'file'
  @ApiTags("Posts and their functions")
  @ApiSecurity("token")
  @UseGuards(AuthGuard)
  @Post("posts")
  @UseInterceptors(FileInterceptor("file", multerOptionsForProducts))
  @ApiOperation({ summary: "Upload a single post photo (alternative to PUT)" })
  @ApiConsumes("multipart/form-data")
  uploadSingleFilePhoto(
    @UploadedFile() file: Express.Multer.File,
    @Body() body: PhotoUUID,
    @Res() res: Response,
    @Req() req: Request,
  ) {
    if (!file) {
      return res.status(400).json({ message: "No file provided" });
    }
    console.log(
      "[POST /photo/posts] uuid:",
      body?.uuid,
      "file originalname:",
      file.originalname,
    );
    // Reuse existing service logic by wrapping single file in array
    return this.PhotoService.uploadPhoto([file], body as any, req, res);
  }
  @ApiSecurity("token")
  @UseGuards(AuthGuard)
  @ApiTags("Posts and their functions")
  @Delete("posts/:uuid")
  async deleteProducts(@Param() param: PhotoUUID) {
    return this.PhotoService.deletePhoto(param);
  }

  //----------------Banners
  @ApiSecurity("token")
  @UseGuards(AuthGuard)
  @UseGuards(AdminGuard)
  @ApiTags("Banners")
  @Put("banners")
  // @UseGuards(AuthGuard)
  @UseInterceptors(FilesInterceptor("files", undefined, multerOptionsForBan))
  @ApiConsumes("multipart/form-data")
  uploadFileBanner(
    @UploadedFiles()
    files: Array<Express.Multer.File>,
    @Body() body: UploadDto,
  ) {
    return this.PhotoService.uploadBan(files, body);
  }
  @ApiSecurity("token")
  @UseGuards(AuthGuard)
  @UseGuards(AdminGuard)
  @ApiTags("Banners")
  @Delete("banners/:uuid")
  async deleteBanners(@Param() param: PhotoUUID) {
    return this.PhotoService.deleteBanners(param);
  }

  @ApiSecurity("token")
  @UseGuards(AuthGuard)
  @UseGuards(AdminGuard)
  @ApiTags("Categories")
  @Put("categories")
  // @UseGuards(AuthGuard)
  @UseInterceptors(FilesInterceptor("files", undefined, multerOptionsForCat))
  @ApiConsumes("multipart/form-data")
  uploadFileCat(
    @UploadedFiles()
    files: Array<Express.Multer.File>,
    @Body() body: UploadDto,
  ) {
    return this.PhotoService.uploadCat(files, body);
  }

  @Put("subscriptions")
  @UseGuards(AuthGuard, AdminGuard)
  @UseInterceptors(FileInterceptor("file", multerOptionsForSubscription))
  @ApiConsumes("multipart/form-data")
  async uploadFileSubscription(
    @UploadedFile() file: Express.Multer.File,
    @Body() body: UploadDto,
  ) {
    console.log("Received file:", file);
    console.log("Received body:", body);
    return this.PhotoService.uploadSubscription(file, body);
  }
  @ApiSecurity("token")
  @UseGuards(AuthGuard)
  @UseGuards(AdminGuard)
  @ApiTags("Post subscriptions & Functions")
  @Delete("subscriptions/:uuid")
  async deleteSubscription(@Param() param: PhotoUUID) {
    return this.PhotoService.deleteSubscription(param);
  }

  @ApiSecurity("token")
  @UseGuards(AuthGuard)
  @ApiTags("Auth")
  @Put("user")
  @UseInterceptors(FileInterceptor("file", muletrOptionsForUsers))
  @ApiConsumes("multipart/form-data")
  uploadFileUser(
    @UploadedFile() file: Express.Multer.File,
    @Body() body: UploadUser,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    if (!file) {
      return res.status(400).json({ message: "No file provided" });
    }
    return this.PhotoService.uploadUser(file, body, req, res);
  }
  @ApiSecurity("token")
  @UseGuards(AuthGuard)
  @UseGuards(AdminGuard)
  @ApiTags("Auth")
  @Delete("user/:uuid")
  async deleteUser(@Param() param: PhotoUUID) {
    return this.PhotoService.deleteUser(param);
  }

  @ApiSecurity("token")
  @UseGuards(AuthGuard)
  @ApiTags("Vlog and Functions")
  @Post("vlog")
  @UseInterceptors(FileInterceptor("file", multerOptionForVlog))
  @ApiConsumes("multipart/form-data")
  uploadVlogPhoto(
    @UploadedFile()
    file: Express.Multer.File,
    @Body() body: uploadFile,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    return this.PhotoService.uploadVlog(file, body, req, res);
  }
  @ApiSecurity("token")
  @UseGuards(AuthGuard)
  @UseGuards(AdminGuard)
  @ApiTags("Vlog and Functions")
  @Delete("vlog/:uuid")
  async deleteVlog(@Param() param: PhotoUUID) {
    return this.PhotoService.deleteVlog(param);
  }
  @ApiSecurity("token")
  @UseGuards(AuthGuard)
  @ApiTags("Brand and Functions")
  @Post("brand")
  @UseInterceptors(FileInterceptor("file", multerOptionsForBrand))
  @ApiConsumes("multipart/form-data")
  uploadBrandIcon(
    @UploadedFile()
    file: Express.Multer.File,
    @Body() body: uploadFile,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    return this.PhotoService.uploadBrand(file, body, req, res);
  }
  @ApiSecurity("token")
  @UseGuards(AuthGuard)
  @UseGuards(AdminGuard)
  @ApiTags("Brand and Functions")
  @Delete("brand/:uuid")
  async deleteBrandIcon(@Param() param: PhotoUUID) {
    return this.PhotoService.deleteBrand(param);
  }
  @ApiSecurity("token")
  @UseGuards(AuthGuard)
  @ApiTags("Models and Functions")
  @Post("models")
  @UseInterceptors(FileInterceptor("file", multerOptionsForModel))
  @ApiConsumes("multipart/form-data")
  uploadModelIcon(
    @UploadedFile()
    file: Express.Multer.File,
    @Body() body: uploadFile,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    return this.PhotoService.uploadModel(file, body, req, res);
  }
  @ApiSecurity("token")
  @UseGuards(AuthGuard)
  @UseGuards(AdminGuard)
  @ApiTags("Models and Functions")
  @Delete("models/:uuid")
  async deleteModelIcon(@Param() param: PhotoUUID) {
    return this.PhotoService.deleteModel(param);
  }
}
