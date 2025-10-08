import 'package:auto_tm/screens/filter_screen/controller/filter_controller.dart';
import 'package:auto_tm/screens/filter_screen/widgets/filter_result_page.dart';
import 'package:auto_tm/ui_components/colors.dart';
import 'package:auto_tm/ui_components/styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ModelSelection extends StatefulWidget {
  final String brandUuid;
  final String brandName;

  const ModelSelection({
    super.key,
    required this.brandUuid,
    required this.brandName,
  });

  @override
  State<ModelSelection> createState() => _ModelSelectionState();
}

class _ModelSelectionState extends State<ModelSelection> {
  final controller = Get.find<FilterController>();

  @override
  void initState() {
    super.initState();
    controller.fetchModels(widget.brandUuid);
  }

  @override
  void dispose() {
    controller.modelSearchController.clear();
    controller.filterModels('');
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
        title: Text('Model'.tr),
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [_buildSearchBar(context), _buildModelList(context)],
        ),
      ),
    );
  }

  /// Builds the search input field.
  Widget _buildSearchBar(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        onChanged: controller.filterModels,
        controller: controller.modelSearchController,
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

  /// Builds the main vertical, scrollable list of all models.
  Widget _buildModelList(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }

        return ListView.separated(
          itemCount: controller.filteredModels.length + 1,
          separatorBuilder: (context, index) =>
              const Divider(height: 1, indent: 16, endIndent: 16),
          itemBuilder: (context, index) {
            // --- THIS IS THE CHANGE ---
            // The "Select all" option is now styled like a navigation button.
            if (index == 0) {
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
                  controller.selectedBrandUuid.value = widget.brandUuid;
                  controller.selectedBrand.value = widget.brandName;
                  controller.selectedModel.value = '';
                  controller.selectedModelUuid.value = '';
                  controller.searchProducts();
                  Get.to(() => FilterResultPage());
                },
              );
            }

            // The rest of the list items for models remain the same
            final modelIndex = index - 1;
            final model = controller.filteredModels[modelIndex];
            final bool isSelected =
                controller.selectedModelUuid.value == model['uuid'];

            return ListTile(
              leading: Icon(
                Icons.directions_car,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              title: Text(
                model['name'],
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              trailing: Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: isSelected
                    ? theme.colorScheme.onSurface
                    : Colors.grey,
              ),
              onTap: () {
                controller.selectedBrandUuid.value = widget.brandUuid;
                controller.selectedModelUuid.value = model['uuid'];
                controller.selectedBrand.value = widget.brandName;
                controller.selectedModel.value = model['name'];
                controller.searchProducts();
                Get.to(() => FilterResultPage());
              },
            );
          },
        );
      }),
    );
  }
}
