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
    controller.ensureBrandModelCachesLoaded().whenComplete(() {
      controller.fetchMyPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // RESPONSIVE: Calculate cross-axis count based on screen width
    final double screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = (screenWidth / 250).floor().clamp(1, 4);

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
              if (controller.isLoadingP.value && controller.posts.isEmpty) {
                return SliverToBoxAdapter(
                  child: _buildLoadingShimmer(context, crossAxisCount),
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

  // REFACTORED: Extracted loading shimmer for clarity
  Widget _buildLoadingShimmer(BuildContext context, int crossAxisCount) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 600, // Fixed height to prevent unbounded constraints
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 8,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 20,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 24,
                        width: 100,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            height: 20,
                            width: 50,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            height: 20,
                            width: 70,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
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
