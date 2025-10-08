import 'package:auto_tm/screens/filter_screen/controller/filter_controller.dart';
import 'package:auto_tm/screens/home_screen/controller/banner_controller.dart';
import 'package:auto_tm/screens/home_screen/controller/home_controller.dart';
import 'package:auto_tm/screens/home_screen/widgets/post_item.dart';
import 'package:auto_tm/screens/home_screen/widgets/post_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Your other imports
import 'package:auto_tm/screens/filter_screen/widgets/brand_selection.dart';
// import 'package:auto_tm/screens/home_screen/widgets/banner_slider.dart'; // temporarily disabled
import 'package:auto_tm/screens/home_screen/widgets/bottom_sheet_lang.dart';
import 'package:auto_tm/screens/search_screen/search_screen.dart';
import 'package:auto_tm/ui_components/colors.dart';
import 'package:auto_tm/ui_components/images.dart';
import 'package:flutter_svg/flutter_svg.dart';
// import 'package:auto_tm/screens/post_details_screen/model/post_model.dart'; // not used directly here
import 'package:auto_tm/utils/color_extensions.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final HomeController controller = Get.put(HomeController());
  final FilterController filterController = Get.find<FilterController>();
  final BannerController bannerController = Get.put(BannerController());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surface.alphaPct(0.95),
              theme
                  .colorScheme
                  .surface, // use surface instead of deprecated background
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: controller.refreshData,
            child: CustomScrollView(
              controller: controller.scrollController,
              slivers: [
                _buildSliverHeader(context, theme),
                _buildSliverContent(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  SliverAppBar _buildSliverHeader(BuildContext context, ThemeData theme) {
    return SliverAppBar(
      backgroundColor: theme.colorScheme.surface.alphaPct(0.85),
      surfaceTintColor: Colors.transparent,
      pinned: true,
      floating: true,
      centerTitle: true,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Get.bottomSheet(BottomSheetLang(width: context.width)),
        icon: SvgPicture.asset(
          AppImages.gear,
          height: 20,
          width: 20,
          colorFilter: ColorFilter.mode(
            theme.colorScheme.onSurface,
            BlendMode.srcIn,
          ),
        ),
      ),
      title: SvgPicture.asset(AppImages.appLogoLittle, height: 20),
      actions: [
        IconButton(
          onPressed: () => Get.to(() => SearchScreen()),
          icon: SvgPicture.asset(
            AppImages.search,
            height: 20,
            width: 20,
            colorFilter: ColorFilter.mode(
              theme.colorScheme.onSurface,
              BlendMode.srcIn,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliverContent(ThemeData theme) {
    return Obx(() {
      if (controller.initialLoad.value) {
        return _buildSliverShimmerView(theme);
      } else if (controller.posts.isEmpty) {
        return _buildSliverEmptyView(theme);
      } else {
        return _buildSliverDataView(theme);
      }
    });
  }

  Widget _buildSliverShimmerView(ThemeData theme) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            IgnorePointer(child: _FilterBar(theme: theme)),
            const SizedBox(height: 24),
            // IgnorePointer(child: BannerSlider()),
            const SizedBox(height: 24),
            IgnorePointer(
              child: _PostsHeader(theme: theme, controller: controller),
            ),
            const SizedBox(height: 16),
            ...List.generate(5, (_) => const PostItemShimmer()),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverEmptyView(ThemeData theme) {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                _FilterBar(theme: theme),
                const SizedBox(height: 24),
                // BannerSlider(),
                const SizedBox(height: 24),
                _PostsHeader(theme: theme, controller: controller),
              ],
            ),
          ),
          _EmptyPosts(theme: theme),
        ],
      ),
    );
  }

  Widget _buildSliverDataView(ThemeData theme) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          // The very first item is the static header content
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _FilterBar(theme: theme),
                  const SizedBox(height: 24),
                  // BannerSlider(),
                  const SizedBox(height: 24),
                  _PostsHeader(theme: theme, controller: controller),
                  const SizedBox(height: 16),
                ],
              ),
            );
          }
          // Adjust index for the posts list
          final postIndex = index - 1;

          // If the index is out of bounds, it's the pagination loader
          if (postIndex >= controller.posts.length) {
            return Obx(
              () => controller.isLoading.value
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: PostItemShimmer(),
                    )
                  : const SizedBox.shrink(),
            );
          }

          final post = controller.posts[postIndex];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: PostItem(
              uuid: post.uuid,
              brand: post.brand,
              model: post.model,
              price: post.price,
              photoPath: post.photoPath,
              year: post.year,
              milleage: post.milleage,
              currency: post.currency,
              createdAt: post.createdAt,
              subscription: post.subscription,
              location: post.location,
              region: post.region,
            ),
          );
        },
        // Calculate child count: 1 header + all posts + 1 for loader slot
        childCount: 1 + controller.posts.length + 1,
      ),
    );
  }
}

// --- FIX: Full implementations for local widgets are now included ---

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surface.alphaPct(0.9),
        border: Border.all(
          color: theme.colorScheme.onSurface.alphaPct(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.overlayLight,
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => Get.to(() => BrandSelection()),
              borderRadius: BorderRadius.circular(12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.surface.alphaPct(0.15),
                          theme.colorScheme.onSurface.alphaPct(0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.onSurface.withOpacity(0.2),
                      ),
                    ),
                    child: SvgPicture.asset(
                      AppImages.car,
                      height: 18,
                      width: 18,
                      colorFilter: const ColorFilter.mode(
                        AppColors.brandColor,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Find Your Car'.tr,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: theme.colorScheme.onSurface.alphaPct(0.9),
                          ),
                        ),
                        Text(
                          '${'Brand'.tr} • ${'Model'.tr} • ${'Country'.tr}',
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.alphaPct(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            height: 40,
            width: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  theme.colorScheme.onSurface.alphaPct(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          InkWell(
           onTap: () => Get.to(() => BrandSelection()),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.onSurface.alphaPct(0.15),
                    theme.colorScheme.onSurface.alphaPct(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.onSurface.alphaPct(0.2),
                ),
              ),
              child: SvgPicture.asset(
                AppImages.filter,
                height: 18,
                width: 18,
                colorFilter: ColorFilter.mode(
                  theme.colorScheme.onSurface,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostsHeader extends StatelessWidget {
  const _PostsHeader({required this.theme, required this.controller});
  final ThemeData theme;
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            theme.colorScheme.onSurface.alphaPct(0.02),
            theme.colorScheme.onSurface.alphaPct(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.onSurface.alphaPct(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Latest Posts'.tr,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.alphaPct(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Obx(
              () => Text(
                '${controller.posts.length} ${'items'.tr}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPosts extends StatelessWidget {
  const _EmptyPosts({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.surface.alphaPct(0.9),
                  theme.colorScheme.primaryContainer.alphaPct(0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outline.alphaPct(0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withOpacity(
                    0.1,
                  ), // shadowColor not deprecated; keep as-is
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.brandColor.alphaPct(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.car_rental_outlined,
                    size: 48,
                    color: AppColors.brandColor.alphaPct(0.8),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No Posts Found'.tr,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try adjusting your filters or check back later for new posts.'
                      .tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.alphaPct(0.7),
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
