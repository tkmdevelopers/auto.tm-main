import 'package:auto_tm/screens/post_screen/controller/post_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:auto_tm/utils/navigation_utils.dart';

/// Shows a searchable bottom sheet for selecting a brand.
///
/// [onBrandSelected] is called with `(brandUuid, brandName)` when the user
/// picks a brand.
/// [onClose] should safely close the overlay (e.g. `NavigationUtils.safePop`).
Future<void> showBrandBottomSheet(
  BuildContext context, {
  required PostController postController,
  required void Function(String uuid, String name) onBrandSelected,
  required VoidCallback onClose,
}) async {
  final theme = Theme.of(context);
  // Reset brand search query each time sheet opens
  postController.brandSearchQuery.value = '';

  return Get.bottomSheet(
    Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Select Brand".tr,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search brand...'.tr,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (value) {
                postController.brandSearchQuery.value = value;
              },
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Obx(() {
              if (postController.isLoadingB.value) {
                return const Center(child: CircularProgressIndicator());
              }
              final brands = postController.filteredBrands;
              if (brands.isEmpty) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("No brands found".tr),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () =>
                          postController.fetchBrands(forceRefresh: true),
                      icon: const Icon(Icons.refresh),
                      label: Text('post_retry'.tr),
                    ),
                  ],
                );
              }
              return ListView.builder(
                itemCount: brands.length,
                itemBuilder: (context, index) {
                  final brand = brands[index];
                  return RadioListTile(
                    title: Text(
                      brand.name,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                    ),
                    value: brand.uuid,
                    groupValue: postController.selectedBrandUuid.value,
                    onChanged: (newValue) {
                      if (!NavigationUtils.throttle('brand_select')) return;
                      onBrandSelected(brand.uuid, brand.name);
                      if (Get.isBottomSheetOpen == true) onClose();
                    },
                    activeColor: theme.colorScheme.onSurface,
                  );
                },
              );
            }),
          ),
        ],
      ),
    ),
    isScrollControlled: true,
  );
}

/// Shows a searchable bottom sheet for selecting a model.
///
/// [onModelSelected] is called with `(modelUuid, modelName)`.
/// [onClose] should safely close the overlay.
Future<void> showModelBottomSheet(
  BuildContext context, {
  required PostController postController,
  required void Function(String uuid, String name) onModelSelected,
  required VoidCallback onClose,
}) async {
  final theme = Theme.of(context);
  // Reset model search query each open
  postController.searchModel.value = '';

  return Get.bottomSheet(
    Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Select Model".tr,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search model...'.tr,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (value) {
                postController.searchModel.value = value;
              },
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Obx(() {
              if (postController.isLoadingM.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final models = postController.filteredModels;
              if (models.isEmpty) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("No models found".tr),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => postController.fetchModels(
                        postController.selectedBrandUuid.value,
                        forceRefresh: true,
                      ),
                      icon: const Icon(Icons.refresh),
                      label: Text('post_retry'.tr),
                    ),
                  ],
                );
              }
              return ListView.builder(
                itemCount: models.length,
                itemBuilder: (context, index) {
                  final model = models[index];
                  return ListTile(
                    title: Text(
                      model.name,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                    ),
                    onTap: () {
                      if (!NavigationUtils.throttle('model_select')) return;
                      onModelSelected(model.uuid, model.name);
                      if (Get.isBottomSheetOpen == true) onClose();
                    },
                  );
                },
              );
            }),
          ),
        ],
      ),
    ),
    isScrollControlled: true,
  );
}

/// Shows a generic options bottom sheet (e.g. condition, engine type,
/// transmission).
///
/// Each entry in [options] must have `'value'` (English key) and
/// `'displayKey'` (localisation key / display text).
/// [selectedValue] is the reactive string that will be updated on selection.
/// [onClose] should safely close the overlay.
Future<void> showOptionsBottomSheet(
  BuildContext context, {
  required String title,
  required List<Map<String, String>> options,
  required RxString selectedValue,
  required VoidCallback onClose,
}) async {
  final theme = Theme.of(context);
  return Get.bottomSheet(
    Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (context, index) {
                final optionData = options[index];
                final String englishValue = optionData['value']!;
                final String displayKey = optionData['displayKey']!;
                bool isSelected = selectedValue.value == englishValue;

                return ListTile(
                  title: Text(
                    displayKey.tr,
                    style: TextStyle(
                      color: isSelected
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(
                          Icons.check_circle_rounded,
                          color: theme.colorScheme.onSurface,
                        )
                      : null,
                  onTap: () {
                    if (!NavigationUtils.throttle('option_select')) return;
                    selectedValue.value = englishValue;
                    // Mark form dirty / changed for partial save logic
                    try {
                      final pc = Get.find<PostController>();
                      pc.markFieldChanged();
                    } catch (_) {}
                    onClose();
                  },
                );
              },
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    ),
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
  );
}

/// Shows a bottom sheet to pick engine displacement in litres.
///
/// Updates [postController.enginePower] with the selected value.
/// [onClose] should safely close the overlay.
Future<void> showEnginePowerBottomSheet(
  BuildContext context, {
  required PostController postController,
  required VoidCallback onClose,
}) async {
  final theme = Theme.of(context);
  final sizes = <double>[];
  // Common engine displacements from 0.6L to 10.0L
  for (double v = 0.6; v <= 2.0; v += 0.1) {
    sizes.add(double.parse(v.toStringAsFixed(1)));
  }
  for (double v = 2.0; v <= 6.0; v += 0.2) {
    sizes.add(double.parse(v.toStringAsFixed(1)));
  }
  for (double v = 6.5; v <= 10.0; v += 0.5) {
    sizes.add(double.parse(v.toStringAsFixed(1)));
  }
  // Deduplicate (2.0 added twice) then sort
  final setSizes = sizes.toSet().toList()..sort();
  final selectedRaw = postController.enginePower.text;
  await Get.bottomSheet(
    Container(
      height: MediaQuery.of(context).size.height * 0.55,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Select Engine Size (L)'.tr,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: setSizes.length,
              itemBuilder: (context, index) {
                final v = setSizes[index];
                final label = v
                    .toStringAsFixed(1)
                    .replaceAll(RegExp(r'\.0'), '.0');
                final isSelected =
                    selectedRaw == label ||
                    selectedRaw == label.replaceAll('.0', '');
                return ListTile(
                  title: Text(
                    '$label L',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(
                          Icons.check_circle_rounded,
                          color: theme.colorScheme.onSurface,
                        )
                      : null,
                  onTap: () {
                    if (!NavigationUtils.throttle('engine_size_select')) return;
                    postController.enginePower.text = v.toStringAsFixed(1);
                    postController.markFieldChanged();
                    onClose();
                  },
                );
              },
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    ),
    isScrollControlled: true,
  );
}

/// Shows a bottom sheet to pick a manufacturing year (descending from current
/// year to 1980).
///
/// Updates [postController.selectedYear] and [postController.selectedDate].
/// [onClose] should safely close the overlay.
Future<void> showYearBottomSheet(
  BuildContext context, {
  required PostController postController,
  required VoidCallback onClose,
}) async {
  final theme = Theme.of(context);
  final currentYear = DateTime.now().year;
  final years = [for (int y = currentYear; y >= 1980; y--) y];
  await Get.bottomSheet(
    Container(
      height: MediaQuery.of(context).size.height * 0.55,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Select Year'.tr,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: years.length,
              itemBuilder: (context, index) {
                final year = years[index];
                final isSelected =
                    postController.selectedYear.value == year.toString();
                return ListTile(
                  title: Text(
                    year.toString(),
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(
                          Icons.check_circle_rounded,
                          color: theme.colorScheme.onSurface,
                        )
                      : null,
                  onTap: () {
                    if (!NavigationUtils.throttle('year_select')) return;
                    postController.selectedYear.value = year.toString();
                    postController.selectedDate.value = DateTime(year, 1, 1);
                    postController.markFieldChanged();
                    onClose();
                  },
                );
              },
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    ),
    isScrollControlled: true,
  );
}

/// Shows a bottom sheet for selecting a car color.
Future<void> showColorBottomSheet(
  BuildContext context, {
  required PostController postController,
  required VoidCallback onClose,
}) async {
  final theme = Theme.of(context);
  final allColors = [
    'White',
    'Black',
    'Red',
    'Yellow',
    'Green',
    'Grey',
    'Silver',
    'Blue',
    'Orange',
    'Metallic',
    'Matte',
    'Pink',
    'Brown',
    'Transparent',
  ];

  return Get.bottomSheet(
    Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Select Color".tr,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: allColors.length,
              itemBuilder: (context, index) {
                final color = allColors[index];
                final isSelected = postController.selectedColor.value == color;
                return ListTile(
                  leading: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _getColor(color),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                  ),
                  title: Text(
                    color.tr,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(
                          Icons.check_circle_rounded,
                          color: theme.colorScheme.onSurface,
                        )
                      : null,
                  onTap: () {
                    if (!NavigationUtils.throttle('color_select')) return;
                    postController.selectedColor.value = color;
                    postController.markFieldChanged();
                    onClose();
                  },
                );
              },
            ),
          ),
        ],
      ),
    ),
    isScrollControlled: true,
  );
}

Color _getColor(String colorName) {
  switch (colorName.toLowerCase()) {
    case 'white':
      return Colors.white;
    case 'black':
      return Colors.black;
    case 'red':
      return Colors.red;
    case 'yellow':
      return Colors.yellow;
    case 'green':
      return Colors.green;
    case 'grey':
      return Colors.grey;
    case 'silver':
      return Colors.grey[400]!;
    case 'blue':
      return Colors.blue;
    case 'orange':
      return Colors.orange;
    case 'metallic':
      return Colors.grey[300]!;
    case 'matte':
      return Colors.black87;
    case 'pink':
      return Colors.pink;
    case 'brown':
      return Colors.brown;
    default:
      return Colors.transparent;
  }
}
