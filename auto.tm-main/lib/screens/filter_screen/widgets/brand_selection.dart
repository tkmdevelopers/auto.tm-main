import 'package:auto_tm/utils/color_extensions.dart';
import 'package:auto_tm/screens/filter_screen/controller/brand_controller.dart';
import 'package:auto_tm/screens/filter_screen/controller/filter_controller.dart';
// Removed direct navigation to FilterResultPage; we now return to origin screen.
import 'package:auto_tm/screens/filter_screen/widgets/location_picker_component.dart';
import 'package:auto_tm/screens/filter_screen/widgets/filter_result_page.dart';
import 'package:auto_tm/screens/filter_screen/widgets/model_selection.dart';
import 'package:auto_tm/ui_components/colors.dart';
import 'package:auto_tm/ui_components/styles.dart';
import 'package:auto_tm/utils/key.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BrandSelection extends StatefulWidget {
  const BrandSelection({super.key, this.origin = 'filter'});

  // origin meanings:
  //  'initial' / 'directHome' -> first-time flow (hasn't seen results yet); after model selection navigate to results.
  //  'filter'                -> editing filters only.
  //  'results'               -> came from results; live update.

  /// Origin of navigation: 'filter' (came from FilterScreen) or 'results' (came from FilterResultPage).
  final String origin;

  @override
  State<BrandSelection> createState() => _BrandSelectionState();
}

class _BrandSelectionState extends State<BrandSelection> {
  final FilterController controller = Get.find<FilterController>();
  final BrandController brandController = Get.isRegistered<BrandController>()
      ? Get.find<BrandController>()
      : Get.put(BrandController());

  late final TextEditingController searchController;

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
    if (controller.brands.isEmpty) {
      controller.fetchBrands();
    }
    brandController.refreshData();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        backgroundColor: theme.appBarTheme.backgroundColor,
        surfaceTintColor: theme.appBarTheme.backgroundColor,
        title: Text('Brand'.tr),
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        // Use a Column for a fixed top section and a scrollable bottom list
        child: Column(
          children: [
            _buildSearchBar(context),
            _buildBrandHistory(context),
            // The main list of brands is now wrapped in Expanded and uses
            // ListView.builder for high-performance, lazy-loaded scrolling.
            _buildBrandList(context),
          ],
        ),
      ),
    );
  }

  /// Builds the search input field.
  Widget _buildSearchBar(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: TextField(
        controller: searchController,
        onChanged: (val) => controller.filterBrands(val),
        decoration: InputDecoration(
          hintText: 'Search'.tr,
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.textTertiaryColor,
          ),
          filled: true,
          fillColor: theme.colorScheme.surface,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColors.textTertiaryColor, //e
              width: 1.0,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColors.textTertiaryColor,
              width: 1.0,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: theme.colorScheme.onSurface, // Color from your theme
              width: 1.5, // A nice visible width for the border
            ),
          ),
        ),
        style: AppStyles.f14w4Th(
          context,
        ).copyWith(color: theme.colorScheme.onSurface),
        cursorColor: theme.colorScheme.onSurface,
      ),
    );
  }

  /// Builds the horizontal list of recently selected brands.
  Widget _buildBrandHistory(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      if (brandController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (brandController.brandHistory.isEmpty) {
        return const SizedBox.shrink(); // Don't show if there's no history
      }

      return Container(
        height: 90,
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: brandController.brandHistory.length,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemBuilder: (context, index) {
            final item = brandController.brandHistory[index];
            final String logoUrl = item.brandLogo ?? '';
            final String brandName = item.brandName;
            final String? modelName = item.modelName;

            return GestureDetector(
              onTap: () {
                // Restore full filter context (Region, Price, etc.)
                if (item.filterState != null) {
                  controller.restoreFilterState(item.filterState!);
                }

                controller.selectBrand(item.brandUuid, item.brandName);
                if (item.modelUuid != null && item.modelName != null) {
                  controller.selectModel(item.modelUuid!, item.modelName!);
                }
                
                if (widget.origin == 'results') {
                  controller.searchProducts();
                  Get.back();
                } else if (widget.origin == 'initial' ||
                    widget.origin == 'directHome') {
                  controller.searchProducts();
                  controller.hasViewedResults.value = true;
                  Get.offAll(
                    () => FilterResultPage(),
                    transition: Transition.noTransition,
                    duration: Duration.zero,
                  );
                } else {
                  Get.back();
                }
              },
              child: Container(
                width: 110,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: theme.colorScheme.onSurface.opacityCompat(0.1),
                    width: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: theme.colorScheme.surface,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (logoUrl.isNotEmpty)
                      Image.network(
                        ApiKey.ip + logoUrl,
                        height: 24,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.business,
                              size: 20,
                              color: Colors.grey,
                            ),
                      )
                    else
                      const Icon(Icons.directions_car, size: 20, color: Colors.grey),
                    const SizedBox(height: 4),
                    Text(
                      brandName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (modelName != null)
                      Text(
                        modelName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          color: theme.colorScheme.onSurface.opacityCompat(0.6),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    });
  }

  /// Builds the main vertical, scrollable list of all brands.
  Widget _buildBrandList(BuildContext context) {
    return Expanded(
      child: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }

        // Use ListView.separated for clean dividers between items
        return ListView.separated(
          itemCount:
              controller.filteredBrands.length +
              2, // +2 for "Select All" and CountryPicker
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            // First item is the Country Picker
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: CountryPicker(),
              );
            }

            // Second item is the "Select All" button
            if (index == 1) {
              return ListTile(
                title: Text(
                  'Select all'.tr,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey,
                ),
                onTap: () {
                  // Clear brand/model filters
                  controller.selectedBrandUuids.clear();
                  controller.selectedBrandNames.clear();
                  controller.selectedModelUuids.clear();
                  controller.selectedModelNames.clear();
                  if (widget.origin == 'results') {
                    controller.searchProducts();
                    Get.back();
                  } else if (widget.origin == 'initial' ||
                      widget.origin == 'directHome') {
                    controller.searchProducts();
                    controller.hasViewedResults.value = true;
                    Get.offAll(
                      () => FilterResultPage(),
                      transition: Transition.noTransition,
                      duration: Duration.zero,
                    );
                  } else {
                    // filter origin
                    Get.back();
                  }
                },
              );
            }

            // Adjust index for the brand list
            final brandIndex = index - 2;
            final brand = controller.filteredBrands[brandIndex];
            final String logoUrl = brand.photoPath ?? '';
            final String brandName = brand.name;

            // Use ListTile for a clean, consistent, and semantic row item
            return ListTile(
              leading: logoUrl.isNotEmpty
                  ? Image.network(
                      ApiKey.ip + logoUrl,
                      width: 32,
                      height: 32,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.image_not_supported,
                        size: 24,
                        color: Colors.grey,
                      ),
                    )
                  : const Icon(Icons.car_rental, size: 24, color: Colors.grey),
              title: Text(brandName),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey,
              ),
              onTap: () {
                controller.fetchModels(brand.uuid);
                brandController.addToHistory(
                  brandUuid: brand.uuid,
                  brandName: brandName,
                  brandLogo: logoUrl,
                  filterState: controller.captureFilterState(),
                );
                Get.to(
                  () => ModelSelection(
                    brandUuid: brand.uuid,
                    brandName: brandName,
                    origin: widget.origin,
                  ),
                );
              },
            );
          },
        );
      }),
    );
  }
}
