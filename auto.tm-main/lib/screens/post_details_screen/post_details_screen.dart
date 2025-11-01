import 'package:auto_tm/global_controllers/download_controller.dart';
import 'package:auto_tm/screens/favorites_screen/controller/favorites_controller.dart';
import 'package:auto_tm/screens/post_details_screen/controller/post_details_controller.dart';
import 'package:auto_tm/screens/post_details_screen/widgets/comments.dart';
import 'package:auto_tm/screens/post_details_screen/widgets/comments_carousel.dart';
import 'package:auto_tm/screens/post_details_screen/widgets/post_details_shimmer.dart';
import 'package:auto_tm/screens/post_details_screen/widgets/video_player.dart';
import 'package:auto_tm/screens/post_details_screen/widgets/view_post_photo.dart';
import 'package:auto_tm/screens/post_details_screen/model/post_model.dart';
import 'package:auto_tm/ui_components/colors.dart';
import 'package:auto_tm/ui_components/images.dart';
import 'package:auto_tm/ui_components/styles.dart';
import 'package:auto_tm/utils/cached_image_helper.dart';
import 'package:auto_tm/utils/key.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:auto_tm/utils/navigation_utils.dart';

class PostDetailsScreen extends StatelessWidget {
  PostDetailsScreen({super.key});

  final String uuid = Get.arguments;
  final PostDetailsController detailsController = Get.put(
    PostDetailsController(),
  );
  final FavoritesController favoritesController = Get.put(
    FavoritesController(),
  );
  final downloadController = Get.find<DownloadController>();

  @override
  Widget build(BuildContext context) {
    detailsController.fetchProductDetails(uuid);
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Obx(() {
        if (detailsController.isLoading.value) {
          // return const Center(
          //   child: CircularProgressIndicator.adaptive(
          //     backgroundColor: AppColors.primaryColor,
          //     valueColor: AlwaysStoppedAnimation(AppColors.scaffoldColor),
          //   ),
          // );
          return PostDetailsShimmer();
        }
        final post = detailsController.post;
        // final photos = post.photoPaths;
        // final photos = product.photoPaths;
        return SafeArea(
          child: SingleChildScrollView(
            child: Container(
              color: theme.scaffoldBackgroundColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Photo Slider
                  SizedBox(height: 8),
                  Container(
                    color: theme.scaffoldBackgroundColor,
                    // padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                              ),
                              child: CarouselSlider.builder(
                                itemCount: post.value?.photoPaths.length ?? 0,
                                itemBuilder: (context, index, realIndex) {
                                  final photo = post.value!.photoPaths[index];
                                  final photos = post.value!.photoPaths;

                                  return _CarouselImageItem(
                                    key: PageStorageKey('carousel_img_$index'),
                                    photo: photo,
                                    photos: photos,
                                    index: index,
                                    uuid: uuid,
                                    theme: theme,
                                  );
                                },
                                options: CarouselOptions(
                                  height: 300,
                                  enlargeCenterPage: false,
                                  enableInfiniteScroll: false,
                                  autoPlay: false,
                                  viewportFraction: 1,
                                  disableCenter: true,
                                  onPageChanged: (index, reason) {
                                    detailsController.setCurrentPage(index);
                                  },
                                ),
                              ),
                            ),
                            Positioned(
                              top: 16,
                              left: 16,
                              right: 16,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // Back button matching PostItem style
                                  GestureDetector(
                                    onTap: () => NavigationUtils.close(context),
                                    child: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.surface,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: theme.colorScheme.outline
                                              .withOpacity(0.1),
                                          width: 1.2,
                                        ),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.chevron_left,
                                          size: 20,
                                          color: theme.colorScheme.onSurface
                                              .withOpacity(0.7),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Favorite button re-styled & animated like PostItem
                                  Obx(() {
                                    final isFav = favoritesController.favorites
                                        .contains(uuid);
                                    return GestureDetector(
                                      onTap: () => favoritesController
                                          .toggleFavorite(uuid),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        curve: Curves.easeInOut,
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.surface,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: theme.colorScheme.outline
                                                .withOpacity(0.1),
                                            width: 1.2,
                                          ),
                                          boxShadow: isFav
                                              ? [
                                                  BoxShadow(
                                                    color: theme
                                                        .colorScheme
                                                        .primary
                                                        .withOpacity(0.2),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ]
                                              : [],
                                        ),
                                        child: Center(
                                          child: AnimatedSwitcher(
                                            duration: const Duration(
                                              milliseconds: 300,
                                            ),
                                            transitionBuilder:
                                                (child, animation) =>
                                                    ScaleTransition(
                                                      scale: animation,
                                                      child: child,
                                                    ),
                                            child: Icon(
                                              isFav
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              key: ValueKey<bool>(isFav),
                                              color: isFav
                                                  ? theme.colorScheme.primary
                                                  : theme.colorScheme.onSurface
                                                        .withOpacity(0.7),
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                            Positioned.fill(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(105, 0, 0, 0),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Obx(() {
                                      final photos = detailsController
                                          .post
                                          .value
                                          ?.photoPaths;

                                      if (photos == null || photos.isEmpty) {
                                        return const SizedBox(); // or placeholder
                                      }

                                      return Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: List.generate(photos.length, (
                                          index,
                                        ) {
                                          return Obx(
                                            () => AnimatedContainer(
                                              duration: const Duration(
                                                milliseconds: 300,
                                              ),
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 4,
                                                  ),
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color:
                                                    detailsController
                                                            .currentPage
                                                            .value ==
                                                        index
                                                    ? AppColors.primaryColor
                                                    : AppColors.whiteColor,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                            ),
                                          );
                                        }),
                                      );
                                    }),
                                  ),
                                ),
                              ),
                            ),
                            Obx(() {
                              // Check if post and video exist and are not empty
                              final bool hasVideo =
                                  detailsController.post.value != null &&
                                  detailsController.post.value!.video != null &&
                                  detailsController
                                      .post
                                      .value!
                                      .video!
                                      .isNotEmpty;

                              return Positioned(
                                bottom:
                                    -12.0, // Example: Position at the bottom
                                right: 16.0, // Example: Position to the right
                                child: hasVideo
                                    ? GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () {
                                          Get.to(
                                            () => VideoPlayerPage(),
                                            arguments: detailsController
                                                .post
                                                .value!
                                                .video,
                                          );
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                              colors: [
                                                Color(0xFF1E4EED),
                                                Color(0xFF7FA7F6),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12.0,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          constraints: const BoxConstraints(
                                            minHeight: 36,
                                            minWidth: 140,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.play_circle_outline,
                                                color: AppColors.whiteColor,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 8),
                                              Flexible(
                                                child: Text(
                                                  'post_watch_video'.tr,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 13,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              );
                            }),
                            // Obx(() {
                            //   // Check if post and video exist and are not empty
                            //   final bool hasVideo =
                            //       detailsController.post.value != null &&
                            //       detailsController.post.value!.video != null &&
                            //       detailsController
                            //           .post
                            //           .value!
                            //           .video!
                            //           .isNotEmpty;

                            //   return Positioned(
                            //     bottom:
                            //         -23.0, // Example: Position at the bottom
                            //     right: 16.0, // Example: Position to the right
                            //     child:
                            //         hasVideo
                            //             ? ElevatedButton(
                            //               onPressed: () {
                            //                 print('pressed');
                            //                 Get.to(
                            //                   () => VideoPlayerPage(),
                            //                   arguments:
                            //                       detailsController
                            //                           .post
                            //                           .value!
                            //                           .video,
                            //                 );
                            //               },
                            //               style: ElevatedButton.styleFrom(
                            //                 backgroundColor: Colors.transparent,
                            //                 padding:
                            //                     EdgeInsets
                            //                         .zero, // Remove default padding to control Ink padding
                            //                 // shape: RoundedRectangleBorder(
                            //                 //   borderRadius:
                            //                 //       BorderRadius.circular(
                            //                 //           12.0),
                            //                 // ),
                            //                 elevation:
                            //                     0, // Remove default elevation if desired
                            //                 tapTargetSize:
                            //                     MaterialTapTargetSize
                            //                         .shrinkWrap, // Shrink tap area to content
                            //               ),
                            //               child: Ink(
                            //                 decoration: BoxDecoration(
                            //                   gradient: const LinearGradient(
                            //                     begin: Alignment.centerLeft,
                            //                     end: Alignment.centerRight,
                            //                     colors: [
                            //                       Color(0xFF1E4EED),
                            //                       Color(0xFF7FA7F6),
                            //                     ],
                            //                   ),
                            //                   borderRadius:
                            //                       BorderRadius.circular(12.0),
                            //                 ),
                            //                 child: Container(
                            //                   padding: EdgeInsets.symmetric(
                            //                     horizontal: 10,
                            //                     vertical: 10,
                            //                   ), // Adjust padding for button size
                            //                   // Removed minWidth/minHeight as padding and text size usually define it
                            //                   alignment: Alignment.center,
                            //                   child: Row(
                            //                     children: [
                            //                       Icon(
                            //                         Icons.play_circle_outline,
                            //                         color: AppColors.whiteColor,
                            //                         size: 12,
                            //                       ),
                            //                       SizedBox(width: 10),
                            //                       Text(
                            //                         'Watch the video'.tr,
                            //                         style: TextStyle(
                            //                           color: Colors.white,
                            //                           fontWeight:
                            //                               FontWeight
                            //                                   .w600, // Make text bold for better visibility
                            //                           fontSize:
                            //                               12, // Adjust font size as needed
                            //                         ),
                            //                       ),
                            //                     ],
                            //                   ),
                            //                 ),
                            //               ),
                            //             )
                            //             : const SizedBox.shrink(), // If no video, show nothing
                            //   );
                            // }),
                          ],
                        ),
                        SizedBox(height: 6),
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Text(
                                    '${post.value?.brand} ${post.value?.model}',
                                    style: AppStyles.f24w7.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 8),
                                Container(
                                  margin: EdgeInsets.symmetric(horizontal: 16),
                                  padding: EdgeInsets.symmetric(
                                    vertical: 3,
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: AppColors.dateColor,
                                  ),
                                  child: Text(
                                    '${'Posted date:'.tr} ${post.value != null ? favoritesController.formatDate(post.value!.createdAt) : ''}',
                                    style: AppStyles.f12w4.copyWith(
                                      color: Color(0xFF403A3A),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Status badge
                                if (post.value?.status != true)
                                  Container(
                                    margin: EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      vertical: 6,
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color:
                                          (post.value?.status == null
                                                  ? Colors.orange
                                                  : theme.colorScheme.error)
                                              .withValues(alpha: 0.1),
                                      border: Border.all(
                                        color: post.value?.status == null
                                            ? Colors.orange
                                            : theme.colorScheme.error,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          post.value?.status == null
                                              ? Icons.hourglass_top_rounded
                                              : Icons.cancel_outlined,
                                          size: 16,
                                          color: post.value?.status == null
                                              ? Colors.orange.shade700
                                              : theme.colorScheme.error,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          post.value?.status == null
                                              ? 'post_status_pending_review'.tr
                                              : 'post_status_declined_admin'.tr,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: post.value?.status == null
                                                ? Colors.orange.shade700
                                                : theme.colorScheme.error,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            // if (downloadController.isDownloading.value &&
                            //     downloadController.taskId.isNotEmpty) {
                            //   return Column(
                            //     children: [
                            //       LinearProgressIndicator(
                            //         value:
                            //             downloadController.progress.value /
                            //             100,
                            //       ),
                            //       SizedBox(height: 8),
                            //       Text(
                            //         "Downloading... ${downloadController.progress.value}%",
                            //       ),
                            //     ],
                            //   );
                            // }
                            // return ElevatedButton.icon(
                            //   icon: Icon(Icons.download),
                            //   label: Text("Download PDF"),
                            //   onPressed: () {
                            //     final fileName =
                            //         "${post.value?.brand}_${post.value?.model}_${post.value?.year}.pdf";
                            //     downloadController.startDownload(
                            //       post.value!.file!,
                            //       fileName,
                            //     );
                            //   },
                            // );
                            SizedBox(width: 20),
                            if (post.value?.file != null &&
                                post.value!.file!.path.isNotEmpty)
                              Obx(() {
                                final c = Get.find<DownloadController>();

                                if (c.isDownloading.value) {
                                  return Column(
                                    children: [
                                      LinearProgressIndicator(
                                        value: c.progress.value / 100,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        "Downloading... ${c.progress.value}%", // consider i18n
                                        style: TextStyle(
                                          color: theme
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  );
                                }

                                return Expanded(
                                  child: ElevatedButton.icon(
                                    icon: Icon(
                                      Icons.download,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    label: Text(
                                      "Download car diagnostics".tr,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    onPressed: () {
                                      final fileName =
                                          "AutoTM_${post.value!.brand}_${post.value!.model}_${post.value!.year.toStringAsFixed(0)}.pdf";
                                      final fullUrl =
                                          "${ApiKey.ip}${post.value!.file!.path}";
                                      c.startDownload(fullUrl, fileName);
                                    },
                                  ),
                                );
                              }),
                            SizedBox(width: 15),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Product Info
                  const SizedBox(height: 20),
                  _DynamicCharacteristics(post: post.value, theme: theme),
                  // const SizedBox(
                  //   height: 6,
                  // ),
                  // if(post.value?.description != '')
                  Container(
                    padding: EdgeInsets.all(16),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: theme.scaffoldBackgroundColor,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Seller\'s comment'.tr,
                          style: AppStyles.f20w5.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: 12),
                        Divider(
                          color: AppColors.textTertiaryColor,
                          height: 0.5,
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                post.value?.description.isNotEmpty == true
                                    ? post
                                          .value!
                                          .description // DO NOT translate user text
                                    : '-',
                                style: AppStyles.f16w4.copyWith(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                      ],
                    ),
                  ),
                  SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Comments'.tr,
                          style: AppStyles.f20w5.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: 12),
                        Divider(
                          color: AppColors.textTertiaryColor,
                          height: 0.5,
                        ),
                        SizedBox(height: 16),
                        // Row(
                        //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        //   children: [
                        //     Text("Comments"),
                        //     IconButton(
                        //       icon: Icon(Icons.chevron_right_rounded),
                        //       onPressed: () {
                        //         final uuid = post.value?.uuid;
                        //         if (uuid != null) {
                        //           Get.to(() => CommentsPage(),
                        //               arguments: uuid);
                        //         }
                        //       },
                        //     ),
                        //   ],
                        // ),
                        if (post.value != null)
                          Row(
                            children: [
                              Expanded(
                                child: CommentCarousel(
                                  postId: post.value != null
                                      ? post.value!.uuid
                                      : '',
                                ),
                              ),
                            ],
                          ), // Replace 'YOUR_POST_ID'
                        const SizedBox(height: 20.0),

                        // ElevatedButton(
                        //     onPressed: () {
                        //       final uuid = post.value?.uuid;
                        //       if (uuid != null) {
                        //         Get.to(() => CommentsPage(), arguments: uuid);
                        //       }
                        //     },
                        //     child: Text('Show all'.tr)),
                        ElevatedButton(
                          onPressed: () {
                            final uuid = post.value?.uuid;
                            if (uuid != null) {
                              Get.to(() => CommentsPage(), arguments: uuid);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.textTertiaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            minimumSize: const Size(double.infinity, 30),
                          ),
                          // icon: const Icon(
                          //   Icons.add,
                          //   color: AppColors.scaffoldColor,
                          // ),
                          child: Text(
                            'Show all'.tr,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondaryColor,
                            ),
                            // style: AppStyles.f16w5
                            //     .copyWith(color: AppColors.scaffoldColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 80),
                ],
              ),
            ),
          ),
        );
      }),
      floatingActionButton: Container(
        color: theme.bottomNavigationBarTheme.backgroundColor,
        child: Padding(
          // padding: EdgeInsets.all(16.0.w),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${'Price'.tr}:',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Obx(() {
                    final post = detailsController.post;
                    final priceText =
                        (post.value?.price != null &&
                            post.value?.currency != null)
                        ? '${post.value!.price.toStringAsFixed(0)}${post.value!.currency}'
                        : 'N/A';

                    return Text(
                      priceText,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.notificationColor,
                      ),
                    );
                  }),
                ],
              ),
              // Add to Cart Button
              ElevatedButton(
                onPressed: () {
                  final post = detailsController.post;
                  if (post.value?.phoneNumber != null &&
                      post.value!.phoneNumber.isNotEmpty &&
                      post.value!.phoneNumber != '+993') {
                    detailsController.makePhoneCall(post.value!.phoneNumber);
                  } else {
                    null;
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(80, 50),
                  backgroundColor: AppColors.primaryColor, // Button color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding:
                      // EdgeInsets.symmetric(horizontal: 30.w, vertical: 10.h),
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                ),
                child: Text(
                  'Call'.tr,
                  style: AppStyles.f18w4.copyWith(
                    color: AppColors.scaffoldColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

class _DynamicCharacteristics extends StatelessWidget {
  final Post? post;
  final ThemeData theme;
  const _DynamicCharacteristics({required this.post, required this.theme});

  bool _isNonEmpty(String? v) => v != null && v.trim().isNotEmpty;
  bool _isPositive(num? v) => v != null && v > 0;

  @override
  Widget build(BuildContext context) {
    if (post == null) return const SizedBox.shrink();

    // Region / location display logic (simplified for backend guarantee):
    // Backend sends region exactly as one of: 'Local', 'UAE', 'China'.
    // - Local: show the city (location) if present.
    // - UAE / China: show that region label directly.
    // - Anything else: hide.
    final regionRaw = post!.region.trim();
    final regionLower = regionRaw.toLowerCase();
    final locRaw = post!.location;
    String? displayLocation;
    if (regionLower == 'local') {
      if (_isNonEmpty(locRaw)) displayLocation = locRaw.trim();
    } else if (regionLower == 'uae' || regionLower == 'china') {
      displayLocation = regionRaw; // Already proper case from backend
    }

    final characteristics =
        <_CharacteristicEntry>[
              _CharacteristicEntry(
                icon: AppImages.enginePower,
                label: 'Engine power'.tr,
                value: _isPositive(post!.enginePower)
                    ? '${post!.enginePower.toStringAsFixed(0)} L'
                    : null,
              ),
              _CharacteristicEntry(
                icon: AppImages.transmission,
                label: 'Transmission'.tr,
                value: _isNonEmpty(post!.transmission)
                    ? post!.transmission.tr
                    : null,
              ),
              _CharacteristicEntry(
                icon: AppImages.year,
                label: 'Year'.tr,
                value: _isPositive(post!.year)
                    ? '${post!.year.toStringAsFixed(0)} y.'.tr
                    : null,
              ),
              _CharacteristicEntry(
                icon: AppImages.milleage,
                label: 'Milleage'.tr,
                value: _isPositive(post!.milleage)
                    ? '${post!.milleage.toStringAsFixed(0)} km'.tr
                    : null,
              ),
              _CharacteristicEntry(
                icon: AppImages.carCondition,
                label: 'Car condition'.tr,
                value: _isNonEmpty(post!.condition) ? post!.condition.tr : null,
              ),
              _CharacteristicEntry(
                icon: AppImages.engineType,
                label: 'Engine type'.tr,
                value: _isNonEmpty(post!.engineType)
                    ? post!.engineType.tr
                    : null,
              ),
              _CharacteristicEntry(
                icon: AppImages.vin,
                label: 'VIN',
                value: _isNonEmpty(post!.vinCode) ? post!.vinCode : null,
              ),
              if (displayLocation != null)
                _CharacteristicEntry(
                  icon: AppImages.location,
                  label: 'Location'.tr,
                  // Do not translate standardized region names; only translate if it looks like a key.
                  value: displayLocation,
                ),
              // Exchange info (always show) - standardized keys
              _CharacteristicEntry(
                icon: AppImages.exchange,
                label: 'Exchange'.tr,
                value: (post!.exchange == true)
                    ? 'post_exchange_possible'.tr
                    : 'post_exchange_not_possible'.tr,
              ),
              // Credit info (always show) - standardized keys
              _CharacteristicEntry(
                icon: AppImages.credit,
                label: 'Credit'.tr,
                value: (post!.credit == true)
                    ? 'post_credit_available'.tr
                    : 'post_credit_not_available'.tr,
              ),
            ]
            .where(
              (e) =>
                  e.value != null &&
                  e.value!.trim().isNotEmpty &&
                  e.value != '0',
            )
            .toList();

    if (characteristics.isEmpty) return const SizedBox.shrink();

    // Build rows of two using Wrap for responsive flow
    final rows = <Widget>[];
    for (int i = 0; i < characteristics.length; i += 2) {
      final first = characteristics[i];
      final second = (i + 1) < characteristics.length
          ? characteristics[i + 1]
          : null;
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildCharacteristicsItem(first)),
            const SizedBox(width: 12),
            Expanded(
              child: second != null
                  ? _buildCharacteristicsItem(second)
                  : const SizedBox(),
            ),
          ],
        ),
      );
      if (i + 2 < characteristics.length) rows.add(const SizedBox(height: 10));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: theme.scaffoldBackgroundColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Characteristics'.tr,
            style: AppStyles.f20w5.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: AppColors.textTertiaryColor, height: 0.5),
          const SizedBox(height: 16),
          ...rows,
        ],
      ),
    );
  }

  Widget _buildCharacteristicsItem(_CharacteristicEntry e) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SvgPicture.asset(
          e.icon,
          width: 28,
          height: 28,
          colorFilter: ColorFilter.mode(
            theme.colorScheme.onSurfaceVariant,
            BlendMode.srcIn,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${e.label}:',
                style: AppStyles.f16w6.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  overflow: TextOverflow.ellipsis,
                ),
                maxLines: 2,
              ),
              Text(
                e.value ?? '-',
                style: AppStyles.f14w4.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CharacteristicEntry {
  final String icon;
  final String label;
  final String? value;
  _CharacteristicEntry({
    required this.icon,
    required this.label,
    required this.value,
  });
}

/// Carousel image item with AutomaticKeepAliveClientMixin
/// to prevent disposal and re-initialization when scrolling
class _CarouselImageItem extends StatefulWidget {
  final String photo;
  final List<String> photos;
  final int index;
  final String uuid;
  final ThemeData theme;

  const _CarouselImageItem({
    super.key,
    required this.photo,
    required this.photos,
    required this.index,
    required this.uuid,
    required this.theme,
  });

  @override
  State<_CarouselImageItem> createState() => _CarouselImageItemState();
}

class _CarouselImageItemState extends State<_CarouselImageItem>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Keep widget alive when off-screen!

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    // Wrap in AutomaticKeepAlive to ensure proper keep-alive behavior
    return AutomaticKeepAlive(
      child: GestureDetector(
        onTap: () {
          if (widget.photos.isNotEmpty) {
            Get.to(
              () => ViewPostPhotoScreen(
                imageUrls: widget.photos,
                currentIndex: widget.index,
                postUuid: widget.uuid,
                heroGroupTag: widget.uuid,
              ),
              transition: Transition.fadeIn,
              curve: Curves.easeInOut,
              duration: const Duration(milliseconds: 220),
            );
          }
        },
        child: Container(
          width: double.infinity,
          height: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: widget.theme.colorScheme.surfaceContainerHighest,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: widget.photo.isNotEmpty
                ? CachedImageHelper.buildPostImage(
                    photoPath: widget.photo,
                    baseUrl: ApiKey.ip,
                    width: 800,
                    height: 600,
                    fit: BoxFit.contain,
                    isThumbnail: false,
                    fallbackUrl: AppImages.defaultImagePng,
                  )
                : Image.asset(
                    AppImages.defaultImagePng,
                    height: 300,
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),
          ),
        ),
      ), // Close AutomaticKeepAlive
    );
  }
}
