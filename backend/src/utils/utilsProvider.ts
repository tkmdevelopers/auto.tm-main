import { authsProvider } from "src/auth/auth.provider";
import { BannersProvider } from "src/banners/banners.provider";
import { brandsProvider } from "src/brands/brands.provider";
import { CategoriesProvider } from "src/categories/categories.provider";
import { commentsProvider } from "src/comments/comments.provider";
import { FileProvider } from "src/file/file.provider";
import { modelsProvider } from "src/models/models.provider";
import { OtpModule } from "src/otp/otp.module";
import { OtpTempProvider } from "src/otp/otp.provider";
import { PhotoProvider } from "src/photo/photo.provider";
import { postsProvider } from "src/post/post.provider";
import { SubscriptionsProvider } from "src/subscription/subscription.provider";
import { VideoProvider } from "src/video/video.provider";
import { VlogProvider } from "src/vlog/vlog.provider";
import { NotificationProvider } from "src/notification/notification.provider";

export const UtilProviders = [
  ...authsProvider,
  ...postsProvider,
  ...modelsProvider,
  ...brandsProvider,
  ...PhotoProvider,
  ...BannersProvider,
  ...CategoriesProvider,
  ...commentsProvider,
  ...SubscriptionsProvider,
  ...VlogProvider,
  ...VideoProvider,
  ...OtpTempProvider,
  ...FileProvider,
  ...NotificationProvider,
];
