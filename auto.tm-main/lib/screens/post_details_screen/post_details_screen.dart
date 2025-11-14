import 'package:auto_tm/global_controllers/download_controller.dart';
import 'package:auto_tm/screens/favorites_screen/controller/favorites_controller.dart';
import 'package:auto_tm/screens/post_details_screen/controller/post_details_controller.dart';
import 'package:auto_tm/screens/post_details_screen/widgets/post_details_shimmer.dart';
import 'package:auto_tm/screens/post_details_screen/widgets/sections/characteristics_grid_section.dart';
import 'package:auto_tm/screens/post_details_screen/widgets/sections/seller_comment_section.dart';
import 'package:auto_tm/screens/post_details_screen/widgets/sections/comments_preview_section.dart';
import 'package:auto_tm/screens/post_details_screen/widgets/sections/media_carousel_section.dart';
import 'package:auto_tm/screens/post_details_screen/widgets/sections/meta_header_section.dart';
import 'package:auto_tm/screens/post_details_screen/widgets/sections/status_badge_section.dart';
import 'package:auto_tm/screens/post_details_screen/widgets/sections/download_button_section.dart';
import 'package:auto_tm/screens/post_details_screen/widgets/sections/price_call_footer.dart';
import 'package:auto_tm/screens/post_details_screen/model/post_details_state.dart';
import 'package:auto_tm/ui_components/colors.dart';
import 'package:auto_tm/ui_components/styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PostDetailsScreen extends StatefulWidget {
  PostDetailsScreen({super.key});

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  late final String uuid;
  late final PostDetailsController detailsController;
  late final FavoritesController favoritesController;
  late final DownloadController downloadController;

  @override
  void initState() {
    super.initState();
    uuid = Get.arguments;

    // Use Get.put with unique tag to prevent controller reuse across instances
    detailsController = Get.put(
      PostDetailsController(),
      tag: 'post_details_$uuid',
    );
    favoritesController = Get.put(FavoritesController());
    downloadController = Get.find<DownloadController>();

    // Fetch data ONCE in initState to prevent race conditions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      detailsController.fetchProductDetails(uuid);
    });
  }

  @override
  void dispose() {
    // Clean up controller to prevent memory leak (#12)
    Get.delete<PostDetailsController>(tag: 'post_details_$uuid');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Obx(() {
        final s = detailsController.state.value;
        if (s is PostDetailsLoading) {
          return PostDetailsShimmer();
        }
        if (s is PostDetailsError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, color: theme.colorScheme.error, size: 48),
                  const SizedBox(height: 16),
                  Text('post_details_error_title'.tr, style: AppStyles.f20w5.copyWith(color: theme.colorScheme.onSurface)),
                  const SizedBox(height: 8),
                  Text(s.message.tr, textAlign: TextAlign.center, style: AppStyles.f14w4.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => detailsController.fetchProductDetails(uuid),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.textTertiaryColor,
                      minimumSize: const Size(160, 40),
                    ),
                    child: Text('common_retry'.tr, style: AppStyles.f16w5.copyWith(color: AppColors.textSecondaryColor)),
                  ),
                ],
              ),
            ),
          );
        }
        // Ready state
        final readyState = s as PostDetailsReady;
        final post = readyState.post;
        return SafeArea(
          child: SingleChildScrollView(
            child: Container(
              color: theme.scaffoldBackgroundColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  // Photo carousel
                  MediaCarouselSection(
                    post: post,
                    uuid: uuid,
                    detailsController: detailsController,
                    favoritesController: favoritesController,
                  ),
                  const SizedBox(height: 6),
                  // Brand + model + date
                  MetaHeaderSection(
                    post: post,
                    favoritesController: favoritesController,
                    theme: theme,
                  ),
                  const SizedBox(height: 8),
                  // Status badge
                  StatusBadgeSection(
                    post: post,
                    theme: theme,
                  ),
                  const SizedBox(height: 8),
                  // Download button
                  DownloadButtonSection(
                    post: post,
                    downloadController: downloadController,
                    theme: theme,
                  ),
                  const SizedBox(height: 20),
                  // Characteristics grid
                  CharacteristicsGridSection(post: post, theme: theme),
                  // Seller comment
                  SellerCommentSection(post: post, theme: theme),
                  const SizedBox(height: 6),
                  // Comments preview
                  CommentsPreviewSection(
                    postUuid: post.uuid,
                    theme: theme,
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        );
      }),
      floatingActionButton: PriceCallFooter(
        controller: detailsController,
        theme: theme,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
