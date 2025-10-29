import 'package:auto_tm/global_widgets/refresh_indicator.dart';
import 'package:auto_tm/screens/post_screen/controller/post_controller.dart';
import 'package:auto_tm/screens/post_screen/widgets/post_screen.dart';
import 'package:auto_tm/screens/post_screen/widgets/posted_post_item.dart';
import 'controller/upload_manager.dart';
import 'widgets/upload_status_banner.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PostedPostsScreen extends StatefulWidget {
  PostedPostsScreen({super.key, this.initialTabIndex = 0});

  /// Only one tab (Published) now; legacy param kept for backward route compatibility.
  final int initialTabIndex;

  @override
  State<PostedPostsScreen> createState() => _PostedPostsScreenState();
}

class _PostedPostsScreenState extends State<PostedPostsScreen> {
  late final PostController controller;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<PostController>()) {
      controller = Get.find<PostController>();
    } else {
      controller = Get.put(PostController());
    }
    // Preload brand/model caches (don't await UI) then fetch posts.
    controller
        .ensureBrandModelCachesLoaded()
        .whenComplete(() {
          if (mounted) {
            controller.fetchMyPosts();
          }
        })
        .catchError((e) {
          // If cache loading fails, still fetch posts (names may not resolve but posts will show)
          debugPrint('Cache loading failed: $e');
          if (mounted) {
            controller.fetchMyPosts();
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Removed bottom floating button; action now in top app bar
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Adopt HomeScreen SliverAppBar concept
            SliverAppBar(
              backgroundColor: theme.colorScheme.surface.withOpacity(0.85),
              surfaceTintColor: Colors.transparent,
              pinned: true,
              floating: true,
              centerTitle: true,
              elevation: 0,
              automaticallyImplyLeading: false,
              title: Text(
                'post_my_posts'.tr,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              actions: [
                Obx(() {
                  final locked = Get.isRegistered<UploadManager>()
                      ? Get.find<UploadManager>().isLocked.value
                      : false;
                  final Color bg = locked
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.25)
                      : theme.colorScheme.primary;
                  final Color fg = locked
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                      : theme.colorScheme.onPrimary;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: SizedBox(
                      height: 40,
                      width: 40,
                      child: Material(
                        color: bg,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: locked
                              ? null
                              : () => Get.to(() => const PostScreen()),
                          child: Icon(Icons.add, color: fg, size: 24),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
            const SliverToBoxAdapter(child: UploadStatusBanner()),
            Obx(() {
              // Show shimmer only after 300ms delay (prevents flash on fast loads)
              if (controller.showShimmer.value) {
                return SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList.separated(
                    itemCount: 5,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      return const PostedPostItemShimmer();
                    },
                  ),
                );
              }
              if (controller.posts.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(context),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList.separated(
                  itemCount: controller.posts.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final post = controller.posts[index];
                    final resolvedBrand = controller.resolveBrandName(
                      post.brand,
                    );
                    // Attempt model resolution with brand context
                    final resolvedModel = controller.resolveModelWithBrand(
                      post.modelId.isNotEmpty ? post.modelId : post.model,
                      post.brandId.isNotEmpty ? post.brandId : post.brand,
                    );
                    return PostedPostItem(
                      uuid: post.uuid,
                      brand: resolvedBrand,
                      model: resolvedModel,
                      brandId: post.brandId,
                      modelId: post.modelId,
                      price: post.price,
                      photoPath: post.photoPath,
                      year: post.year,
                      milleage: post.milleage,
                      currency: post.currency,
                      createdAt: post.createdAt,
                      status: post.status,
                    );
                  },
                ),
              );
            }),
            // Removed bottom spacer (no floating button now)
          ],
        ),
      ),
    );
  }

  // REFACTORED: Extracted empty state widget for clarity
  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return SRefreshIndicator(
      onRefresh: controller.refreshData,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.car_rental_outlined,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'post_no_published'.tr,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'post_create_first_tip'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Removed unused draft-related time helpers.
}
