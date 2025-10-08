import 'dart:convert';

import 'package:auto_tm/screens/profile_screen/controller/profile_controller.dart';
import 'package:auto_tm/ui_components/colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:auto_tm/utils/navigation_utils.dart';

class LocationController extends GetxController {
  final selectedLocation = Rx<String?>(null);
  final allLocations = <String>[].obs; // changed to observable list
  final filteredLocations = <String>[].obs;
  final searchText = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadLocations(); // load from assets
  }

  Future<void> loadLocations() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/json/city.json',
      );
      final List<dynamic> data = json.decode(response);

      // extract the `name` field from each item
      final names = data.map((e) => e['name'].toString()).toList();

      allLocations.assignAll(names);
      filteredLocations.assignAll(names);
    } catch (e) {
      if (kDebugMode) {
        print("Error loading locations: $e");
      }
    }
  }

  void selectLocation(String location) {
    selectedLocation.value = location;
  }

  String? getSelectedLocation() {
    return selectedLocation.value;
  }

  void filterLocations(String query) {
    searchText.value = query;
    if (query.isEmpty) {
      filteredLocations.assignAll(allLocations);
    } else {
      final lowerCaseQuery = query.toLowerCase();
      filteredLocations.assignAll(
        allLocations.where((location) {
          return location.toLowerCase().contains(lowerCaseQuery);
        }).toList(),
      );
    }
  }

  void resetSearch() {
    searchText.value = '';
    filteredLocations.assignAll(allLocations);
  }
}

// Screen
class SLocationSelectionProfile extends StatelessWidget {
  final LocationController locationController = Get.put(LocationController());
  // Retrieve existing ProfileController singleton (create if absent)
  final ProfileController controller = ProfileController.ensure();

  SLocationSelectionProfile({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 4,
        surfaceTintColor: theme.appBarTheme.backgroundColor,
        backgroundColor: theme.appBarTheme.backgroundColor,
        title: Text(
          "Location".tr,
          style: TextStyle(color: theme.colorScheme.primary),
        ),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: () {
              locationController.resetSearch();
            },
            child: Text(
              "Reset".tr,
              style: TextStyle(color: theme.primaryColor),
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
                color: theme.colorScheme.primaryContainer,
                border: Border.all(
                  color: AppColors.textTertiaryColor,
                  width: 0.5,
                ),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: TextField(
                onChanged: locationController.filterLocations,
                style: TextStyle(color: theme.colorScheme.primary),
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppColors.textTertiaryColor,
                  ),
                  hintText: "Search".tr,
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
            // Location List
            Expanded(
              child: Obx(() {
                return Scrollbar(
                  child: ListView.builder(
                    itemCount: locationController.filteredLocations.length,
                    itemBuilder: (context, index) {
                      final location =
                          locationController.filteredLocations[index];
                      //final isSelected = locationController.selectedLocation.value == location; // Removed direct comparison
                      return Obx(() {
                        // Added Obx inside the itemBuilder
                        final isSelected =
                            locationController.selectedLocation.value ==
                            location;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(6.0),
                              border: Border.all(
                                color: isSelected
                                    ? theme.primaryColor
                                    : AppColors.textTertiaryColor,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: ListTile(
                              title: Text(
                                location,
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              leading: isSelected
                                  ? Icon(
                                      Icons.radio_button_checked,
                                      color: theme.primaryColor,
                                    )
                                  : const Icon(
                                      Icons.radio_button_off,
                                      color: AppColors.textTertiaryColor,
                                    ),
                              onTap: () {
                                locationController.selectLocation(location);
                                controller.location.value = location;
                                NavigationUtils.close(
                                  context,
                                  result: location,
                                );
                              },
                            ),
                          ),
                        );
                      });
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
