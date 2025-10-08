import 'package:auto_tm/global_controllers/download_controller.dart';
import 'package:auto_tm/screens/favorites_screen/controller/favorites_controller.dart';
import 'package:auto_tm/screens/post_details_screen/controller/post_details_controller.dart';
import 'package:auto_tm/screens/post_details_screen/widgets/comments.dart';
import 'package:auto_tm/screens/post_details_screen/widgets/comments_carousel.dart';
import 'package:auto_tm/screens/post_details_screen/widgets/post_details_shimmer.dart';
import 'package:auto_tm/screens/post_details_screen/widgets/video_player.dart';
import 'package:auto_tm/screens/post_details_screen/widgets/view_post_photo.dart';
import 'package:auto_tm/ui_components/colors.dart';
import 'package:auto_tm/ui_components/images.dart';
import 'package:auto_tm/ui_components/styles.dart';
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
                              color: theme.colorScheme.primaryContainer,
                              child: CarouselSlider(
                                items: post.value?.photoPaths.map((photo) {
                                  return GestureDetector(
                                    onTap: () {
                                      final photos = post.value?.photoPaths;
                                      if (photos != null) {
                                        Get.to(
                                          () => ViewPostPhotoScreen(
                                            imageUrls: photos,
                                            currentIndex: detailsController
                                                .currentPage
                                                .value,
                                          ),
                                        );
                                      }
                                    },
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                        10,
                                      ), // Optional: round corners
                                      child: photo.isNotEmpty
                                          ? Image.network(
                                              '${ApiKey.ip}$photo',
                                              // fit: BoxFit.cover,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => Image.asset(
                                                    AppImages.defaultImagePng,
                                                    height: 180,
                                                    width: double.infinity,
                                                    fit: BoxFit.fitWidth,
                                                  ),
                                            )
                                          : Image.asset(
                                              AppImages.defaultImagePng,
                                              height: 180,
                                              width: double.infinity,
                                              // color: ,
                                              fit: BoxFit.fitWidth,
                                            ),
                                    ),
                                  );
                                }).toList(),
                                options: CarouselOptions(
                                  height: 300,
                                  enlargeCenterPage: false,
                                  enableInfiniteScroll: false,
                                  autoPlay: false,
                                  aspectRatio: 16 / 9,
                                  // clipBehavior: Clip.none,
                                  // viewportFraction: 0.4,
                                  viewportFraction: 1,
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
                                  InkWell(
                                    onTap: () => NavigationUtils.close(context),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color:
                                            theme.colorScheme.tertiaryContainer,
                                        borderRadius: BorderRadius.circular(25),
                                        boxShadow: [
                                          BoxShadow(
                                            color: theme.shadowColor,
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.chevron_left,
                                        color: theme.colorScheme.primary,
                                        // size: 20.sp,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    // onTap: onFavoriteToggle,
                                    onTap: () => favoritesController
                                        .toggleFavorite(uuid),
                                    child: Container(
                                      // padding: EdgeInsets.all(4.w),
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color:
                                            theme.colorScheme.tertiaryContainer,
                                        borderRadius: BorderRadius.circular(25),
                                        boxShadow: [
                                          BoxShadow(
                                            color: theme.shadowColor,
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                      child: Obx(() {
                                        final isFavorite = favoritesController
                                            .favorites
                                            .contains(uuid);
                                        return Icon(
                                          // size: 20.sp,
                                          size: 22,
                                          isFavorite
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          color: isFavorite
                                              ? Colors.red
                                              : Colors.red,
                                        );
                                      }),
                                    ),
                                  ),
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
                                    ? Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () {
                                            Get.to(
                                              () => VideoPlayerPage(),
                                              arguments: detailsController
                                                  .post
                                                  .value!
                                                  .video,
                                            );
                                          },
                                          borderRadius: BorderRadius.circular(
                                            12.0,
                                          ),
                                          child: Ink(
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                begin: Alignment.centerLeft,
                                                end: Alignment.centerRight,
                                                colors: [
                                                  Color(0xFF1E4EED),
                                                  Color(0xFF7FA7F6),
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12.0),
                                            ),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                              alignment: Alignment.center,
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons.play_circle_outline,
                                                    color: AppColors.whiteColor,
                                                    size: 12,
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Text(
                                                    'Watch the video'.tr,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
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
                                        "Downloading... ${c.progress.value}%",
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
                  Container(
                    padding: EdgeInsets.all(16),
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
                        SizedBox(height: 12),
                        Divider(
                          color: AppColors.textTertiaryColor,
                          height: 0.5,
                        ),
                        SizedBox(height: 16),
                        Builder(
                          builder: (context) {
                            final characteristics = <Map<String, String>>[];

                            String? enginePowerText;
                            if (post.value?.enginePower != null && post.value!.enginePower != 0) {
                              enginePowerText = post.value!.enginePower.toStringAsFixed(0);
                            }

                            void add(String icon, String label, String? raw) {
                              if (raw == null) return;
                              final v = raw.trim();
                              if (v.isEmpty || v == '-' || v == '--' || v.toLowerCase() == 'null') return;
                              // brand & model excluded per requirement (handled earlier in _buildCharacteristics but skip here too for layout)
                              final lower = label.toLowerCase();
                              if (lower.contains('brand') || lower.contains('model')) return;
                              characteristics.add({'icon': icon, 'key': label, 'value': v});
                            }

                            add(AppImages.enginePower, 'Engine power'.tr, enginePowerText);
                            add(AppImages.transmission, 'Transmission'.tr, post.value?.transmission);
                            add(AppImages.year, 'Year'.tr, post.value?.year != null ? post.value!.year.toStringAsFixed(0) + ' y.' : null);
                            add(AppImages.milleage, 'Milleage'.tr, post.value?.milleage != null ? post.value!.milleage.toStringAsFixed(0) + ' km' : null);
                            add(AppImages.carCondition, 'Car condition'.tr, post.value?.condition);
                            add(AppImages.engineType, 'Engine type'.tr, post.value?.engineType);
                            add(AppImages.vin, 'VIN', post.value?.vinCode);
                            // New: Region (from personalInfo.region)
                            add(AppImages.location, 'Region'.tr, (post.value?.region.isNotEmpty ?? false) ? post.value!.region : 'Local');
                            add(AppImages.location, 'Location'.tr, post.value?.location);

                            if (characteristics.isEmpty) {
                              return Text(
                                'No details'.tr,
                                style: AppStyles.f14w4.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                                ),
                              );
                            }

                            return Column(
                              children: [
                                for (var i = 0; i < characteristics.length; i++) ...[
                                  _buildCharacteristics(
                                    characteristics[i]['icon']!,
                                    characteristics[i]['key']!,
                                    characteristics[i]['value']!,
                                    theme.colorScheme.onSurfaceVariant,
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
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
                                    ? post.value!.description.tr
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

  Widget _buildCharacteristics(
    String icon,
    String key,
    String value,
    Color color,
  ) {
    // Normalize inputs
    final k = key.trim();
    final v = (value).trim();

    // 1. Remove brand & model rows entirely
    final lower = k.toLowerCase();
    if (lower.contains('brand') || lower.contains('model')) {
      return const SizedBox.shrink();
    }

    // 2. Skip empty / placeholder / null-ish values
    if (v.isEmpty || v.toLowerCase() == 'null' || v == '-' || v == '--') {
      return const SizedBox.shrink();
    }

    // 3. Pull colors from theme surface / onSurface for Apple-like subtle contrast
    final theme = Get.context?.theme;
    final onSurface = theme?.colorScheme.onSurface ?? AppColors.textPrimaryColor;
    final primaryTextColor = onSurface.withOpacity(0.92);
    final secondaryTextColor = onSurface.withOpacity(0.60);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset(
            icon,
            width: 20,
            height: 20,
            colorFilter: ColorFilter.mode(onSurface, BlendMode.srcIn), // full onSurface per request
          ),
          const SizedBox(width: 10),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    flex: 5,
                    child: Text(
                      "$k:",
                      style: AppStyles.f14w5.copyWith(
                        color: primaryTextColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        letterSpacing: -0.15,
                        overflow: TextOverflow.ellipsis,
                      ),
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    flex: 7,
                    child: Text(
                      v,
                      style: AppStyles.f14w4.copyWith(
                        color: secondaryTextColor,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
