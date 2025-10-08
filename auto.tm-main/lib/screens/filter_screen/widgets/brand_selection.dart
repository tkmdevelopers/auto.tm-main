import 'package:auto_tm/screens/filter_screen/controller/brand_controller.dart';
import 'package:auto_tm/screens/filter_screen/controller/filter_controller.dart';
import 'package:auto_tm/screens/filter_screen/widgets/filter_result_page.dart';
import 'package:auto_tm/screens/filter_screen/widgets/location_picker_component.dart';
import 'package:auto_tm/screens/filter_screen/widgets/model_selection.dart';
import 'package:auto_tm/ui_components/colors.dart';
import 'package:auto_tm/ui_components/styles.dart';
import 'package:auto_tm/utils/key.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BrandSelection extends StatelessWidget {
  final FilterController controller = Get.find<FilterController>();
  // Use find if already registered, else put.
  final BrandController brandController =
      Get.isRegistered<BrandController>()
          ? Get.find<BrandController>()
          : Get.put(BrandController());

  BrandSelection({super.key}) {
    // Load brands only if list empty to prevent refetch loops when returning
    if (controller.brands.isEmpty) {
      controller.fetchBrands();
    }
    // Ensure local history is loaded and then fetch details for those brands
    brandController.refreshData();
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
        onChanged: controller.filterBrands,
        controller: controller.brandSearchController,
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
        style: AppStyles.f14w4.copyWith(color: theme.colorScheme.onSurface),
        cursorColor: theme.colorScheme.onSurface,
      ),
    );
  }

  /// Builds the horizontal list of recently selected brands.
  Widget _buildBrandHistory(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      if (brandController.isLodaing.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (brandController.brands.isEmpty) {
        return const SizedBox.shrink(); // Don't show if there's no history
      }

      return Container(
        height: 80,
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: brandController.brands.length,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemBuilder: (context, index) {
            final brand = brandController.brands[index];
            final String logoUrl = brand['photo']?['originalPath'] ?? '';
            final String brandName = brand['name'] ?? '';

            return GestureDetector(
              onTap: () {
                controller.fetchModels(brand['uuid']);
                brandController.addToHistory(brand['uuid']);
                Get.to(
                  () => ModelSelection(
                    brandUuid: brand['uuid'],
                    brandName: brandName,
                  ),
                );
              },
              child: Container(
                width: 100,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.dividerColor, width: 0.5),
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
                              size: 24,
                              color: Colors.grey,
                            ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      brandName,
                      style: theme.textTheme.bodySmall,
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
                  controller.searchProducts();
                  Get.to(() => FilterResultPage());
                },
              );
            }

            // Adjust index for the brand list
            final brandIndex = index - 2;
            final brand = controller.filteredBrands[brandIndex];
            final String logoUrl = brand['photo']?['originalPath'] ?? '';
            final String brandName = brand['name'] ?? '';

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
                controller.fetchModels(brand['uuid']);
                brandController.addToHistory(brand['uuid']);
                Get.to(
                  () => ModelSelection(
                    brandUuid: brand['uuid'],
                    brandName: brandName,
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
