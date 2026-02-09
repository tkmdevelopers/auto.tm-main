// final FilterController filterController = Get.put(FilterController());
// filterController.selectedColor.value = color;

import 'package:auto_tm/screens/filter_screen/controller/filter_controller.dart';
import 'package:auto_tm/ui_components/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Controller
class ColorController extends GetxController {
  final selectedColor = Rx<String?>(null); // Changed to single selected color
  final allColors = <String>[
    'White',
    'Black',
    'Red',
    'Yellow',
    'Green',
    'Gray',
    'Silver',
    'Blue',
    'Orange',
    'Metallic',
    'Black sparkle',
    'Pink',
    'Brown',
  ];
  final filteredColors = <String>[].obs;
  final searchText = ''.obs;

  @override
  void onInit() {
    super.onInit();
    filteredColors.assignAll(allColors);
  }

  void toggleColor(String color) {
    if (selectedColor.value == color) {
      selectedColor.value = null; // Deselect if already selected
    } else {
      selectedColor.value = color; // Select the new color
    }
  }

  void filterColors(String query) {
    searchText.value = query;
    if (query.isEmpty) {
      filteredColors.assignAll(allColors);
    } else {
      final lowerCaseQuery = query.toLowerCase();
      filteredColors.assignAll(allColors.where((color) {
        return color.toLowerCase().contains(lowerCaseQuery);
      }).toList());
    }
  }

  void resetSearch() {
    searchText.value = '';
    filteredColors.assignAll(allColors);
    selectedColor.value = null; // Clear selection
  }
}

// Screen
class SFilterColors extends StatelessWidget {
  final ColorController colorController = Get.put(ColorController());
  final FilterController filterController = Get.find<FilterController>();

  SFilterColors({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(elevation:4,
        backgroundColor: theme.appBarTheme.backgroundColor,
        surfaceTintColor: theme.appBarTheme.backgroundColor,
        title: Text(
          "Color".tr,
          style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: () {
              colorController.resetSearch();
            },
            child: Text(
              "Reset".tr,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: AppColors.textTertiaryColor,
                  width: 0.5,
                ),
              ),
              child: TextField(
                onChanged: colorController.filterColors,
                style: TextStyle(color: theme.colorScheme.onSurface),
                decoration: InputDecoration(
                  prefixIcon:
                      Icon(Icons.search, color: AppColors.textTertiaryColor),
                  hintText: "Search",
                  hintStyle: TextStyle(color: AppColors.textTertiaryColor),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 10.0, horizontal: 16.0),
                ),
              ),
            ),
            const SizedBox(height: 20.0),
            // Color List
            Expanded(
              child: Obx(
                () => Scrollbar(
                  child: ListView.builder(
                    itemCount: colorController.filteredColors.length,
                    itemBuilder: (context, index) {
                      final color = colorController.filteredColors[index];
                      //  final isSelected = colorController.selectedColor.value == color; // Changed to single selection
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Obx(() {
                          final isSelected =
                              colorController.selectedColor.value == color;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(12.0),
                              border: Border.all(
                                color: isSelected
                                                    ? theme.colorScheme.onSurface
                                                    : AppColors.textTertiaryColor,
                                width: isSelected ? 1 : 0.5,
                              ),
                            ),
                            child: ListTile(
                              title: Text(
                                color,
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              leading: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _getColor(
                                      color), // Use helper to get color
                                  border: Border.all(
                  color: isSelected
                    ? theme.colorScheme.onSurface
                    : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                              ),
                              trailing: isSelected
                                  ? Icon(
                                      Icons.radio_button_checked,
                                      color: theme.colorScheme.onSurface,
                                    )
                                  : const Icon(
                                      Icons.radio_button_off,
                                      color: AppColors.textTertiaryColor,
                                    ),
                                                onTap: () {
                                                  colorController.toggleColor(color);
                                                  filterController.selectColor(color);
                                                },
                              
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to get color from string
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
      case 'gray':
        return Colors.grey;
      case 'silver':
        return Colors.grey[400]!; // Use a specific shade for silver
      case 'blue':
        return Colors.blue;
      case 'orange':
        return Colors.orange;
      case 'metallic':
        return Colors.grey[300]!; //  light gray for metallic
      case 'black sparkle':
        return Colors.black; //  black, no sparkle in color
      case 'pink':
        return Colors.pink;
      case 'brown':
        return Colors.brown;
      default:
        return Colors.transparent;
    }
  }
}
