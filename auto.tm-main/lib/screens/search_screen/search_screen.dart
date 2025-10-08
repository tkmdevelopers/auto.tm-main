import 'package:auto_tm/screens/filter_screen/controller/filter_controller.dart';
import 'package:auto_tm/screens/filter_screen/widgets/filter_result_page.dart';
import 'package:auto_tm/screens/search_screen/controller/search_controller.dart';
import 'package:auto_tm/screens/search_screen/widgets/searchfield.dart';
import 'package:auto_tm/ui_components/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

class SearchScreen extends StatelessWidget {
  final SearchScreenController controller = Get.put(SearchScreenController());
  final FilterController filterController = Get.put(FilterController());

  SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scrollController = ScrollController();

    // Listen to scroll to trigger pagination
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
              scrollController.position.maxScrollExtent - 100 &&
          controller.hasMore.value &&
          !controller.isLoading.value) {
        controller.searchHints();
      }
    });

    return Scaffold(
      backgroundColor: theme.colorScheme.tertiary,
      body: SafeArea(
        child: Column(
          children: [
            // Top Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.colorScheme.primary, size: 20),
                    onPressed: () => Get.back(),
                    splashRadius: 22,
                  ),
                  Expanded(
                    child: SearchField(
                      hintText: 'Search'.tr,
                      controller: controller.searchTextController,
                      focusNode: controller.searchTextFocus,
                      onChanged: (text) {
                        controller.debouncedSearch(text);
                      },
                      suffixIcon: IconButton(
                        icon: Icon(Icons.close_rounded, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                        onPressed: () {
                          controller.searchTextController.clear();
                          controller.hints.clear();
                        },
                        splashRadius: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Results / Shimmer
            Expanded(
              child: Obx(() {
                final showInitialHint = controller.searchTextController.text.isEmpty;
                final isLoading = controller.isLoading.value;
                final building = controller.indexBuilding.value && !controller.indexReady.value;

                if (showInitialHint) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Type to search'.tr),
                        if (building) ...[
                          const SizedBox(height: 12),
                          const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(height: 6),
                          Text('Optimizing suggestions...'.tr, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6))),
                        ],
                      ],
                    ),
                  );
                }

                if (controller.hints.isEmpty && isLoading) {
                  return buildFullScreenShimmer(context);
                }

                return ListView.builder(
                  controller: scrollController,
                  itemCount: controller.hints.length + (controller.hasMore.value ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == controller.hints.length) {
                      return buildFullScreenShimmer(context);
                    }

                    final hint = controller.hints[index];
                    final brand = hint.brandLabel;
                    final model = hint.modelLabel;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: InkWell(
                        onTap: () {
                          filterController.selectedBrand.value = hint.brandLabel;
                          filterController.selectedBrandUuid.value = hint.brandUuid;
                          filterController.selectedModel.value = hint.modelLabel;
                          filterController.selectedModelUuid.value = hint.modelUuid;
                          filterController.searchProducts();
                          Get.to(() => FilterResultPage());
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                model,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: theme.colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                brand,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: theme.colorScheme.onSurface.withOpacity(0.55),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(height: 8),
                            Divider(height: 0.5, color: AppColors.textTertiaryColor),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // Shimmer Loading
  Widget buildShimmerItem() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 16,
            width: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          SizedBox(height: 8),
          Container(
            height: 14,
            width: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          SizedBox(height: 8),
          Divider(height: 1, color: Colors.grey.shade600),
        ],
      ),
    );
  }

  Widget buildFullScreenShimmer(BuildContext context) {
    final theme = Theme.of(context);
    return Shimmer.fromColors(
      baseColor: theme.colorScheme.primaryContainer,
      highlightColor: Colors.grey[600]!,
      child: ListView.builder(
        itemCount: 8, // Show 8 shimmer lines while loading
        itemBuilder: (context, index) => buildShimmerItem(),
      ),
    );
  }
}
