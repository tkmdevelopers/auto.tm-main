import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiKey {
  static final String ip =
      dotenv.env['API_BASE'] ?? 'https://your-api-base-url.com/';

  static final String apiKey = "${ip}api/v1/";

  // Legacy keys (kept for backward compatibility; prefer ApiClient.to.dio for new code)
  static final String registerKey = "${apiKey}auth/register";
  static final String loginKey = "${apiKey}auth/login";
  static final String setPasswordKey = "${apiKey}auth";
  // Auth endpoints — all POST now (breaking change)
  static final String refreshTokenKey = "${apiKey}auth/refresh"; // POST
  static final String logoutKey = "${apiKey}auth/logout"; // POST
  static final String sendOtpKey = "${apiKey}otp/send"; // POST body: {phone}
  static final String checkOtpKey =
      "${apiKey}otp/verify"; // POST body: {phone, otp}

  static final String getProfileKey = "${apiKey}auth/me";
  static final String getPostsKey = "${apiKey}posts";
  static final String getMyPostsKey = "${apiKey}posts/me";
  static final String searchPostsKey = "${apiKey}posts";
  static final String postPostsKey = "${apiKey}posts";
  static final String postPhotosKey = "${apiKey}photo/posts";
  // Video endpoints (two-step flow):
  // PUT ${apiKey}video  -> create video record (returns video uuid)
  // POST ${apiKey}video/upload -> upload actual file with postId reference (and optionally videoId)
  static final String videoCreateKey = "${apiKey}video"; // PUT
  static final String videoUploadKey = "${apiKey}video/upload"; // POST
  static final String getBrandsKey = "${apiKey}brands";
  static final String getBrandsHistoryKey = "${apiKey}brands/list";
  static final String getModelsKey = "${apiKey}models";
  static final String getBannersKey = "${apiKey}banners";
  static final String getCommentsKey = "${apiKey}comments";
  static final String postCommentsKey = "${apiKey}comments";
  static final String getPremiumKey = "${apiKey}subscription";
  static final String postPremiumKey = "${apiKey}subscription/order";
  static final String getBlogsKey = "${apiKey}vlog";
  static final String postBlogPhotoKey = "${apiKey}photo/vlog";
  static final String getOneBlogKey = "${apiKey}vlog/";
  static final String postBlogsKey = "${apiKey}vlog";
  static final String putUserPhotoKey = "${apiKey}photo/user";
  static final String setFirebaseKey = "${apiKey}auth/setFirebase";
  // static final String getProductsKey = "${apiKey}products";
  // static final String getProductDetailsKey = "${apiKey}products/";
  static final String getCategoriesKey = "${apiKey}categories";
  static final String getFavoritesKey = "${apiKey}posts/list";
  // static final String getOrdersKey = "${apiKey}orders";
  static final String subscribeToBrandKey = "${apiKey}brands/subscribe";
  static final String unsubscribeToBrandKey = "${apiKey}brands/unsubscribe";
}
