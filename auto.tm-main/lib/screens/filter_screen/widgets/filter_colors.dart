import 'package:auto_tm/screens/filter_screen/controller/filter_controller.dart';
import 'package:auto_tm/ui_components/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Controller
class ColorController extends GetxController {
  final selectedColors = <String>{}.obs; 
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
    
    // Initialize from FilterController if it exists
    try {
      final filterController = Get.find<FilterController>();
      selectedColors.assignAll(filterController.selectedColors);
    } catch (_) {}
  }

  void toggleColor(String color) {
    if (selectedColors.contains(color)) {
      selectedColors.remove(color);
    } else {
      selectedColors.add(color);
    }
  }

  void filterColors(String query) {
    searchText.value = query;
    if (query.isEmpty) {
      filteredColors.assignAll(allColors);
    } else {
      final lowerCaseQuery = query.toLowerCase();
      filteredColors.assignAll(
        allColors.where((color) {
          return color.toLowerCase().contains(lowerCaseQuery);
        }).toList(),
      );
    }
  }

  void resetSearch() {
    searchText.value = '';
    filteredColors.assignAll(allColors);
    selectedColors.clear();
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
      appBar: AppBar(
        elevation: 4,
        backgroundColor: theme.appBarTheme.backgroundColor,
        surfaceTintColor: theme.appBarTheme.backgroundColor,
        title: Text(
          "Color".tr,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: () {
              colorController.resetSearch();
              filterController.selectedColors.clear();
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
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppColors.textTertiaryColor,
                  ),
                  hintText: "Search",
                  hintStyle: TextStyle(color: AppColors.textTertiaryColor),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10.0,
                    horizontal: 16.0,
                  ),
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
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Obx(() {
                          final isSelected =
                              colorController.selectedColors.contains(color);
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
                                    color,
                                  ), // Use helper to get color
                                  border: Border.all(
                                    color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                              ),
                              trailing: isSelected
                                  ? Icon(
                                      Icons.check_circle_rounded,
                                      color: theme.colorScheme.onSurface,
                                    )
                                  : Icon(
                                      Icons.circle_outlined,
                                      color: AppColors.textTertiaryColor.withOpacity(0.3),
                                    ),
                              onTap: () {
                                colorController.toggleColor(color);
                                filterController.toggleColor(color);
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