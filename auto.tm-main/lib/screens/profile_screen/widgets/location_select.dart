import 'dart:convert';

import 'package:auto_tm/screens/profile_screen/controller/profile_controller.dart';
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
        elevation: 2,
        surfaceTintColor: theme.appBarTheme.backgroundColor,
        backgroundColor: theme.appBarTheme.backgroundColor,
        title: Text(
          "Location".tr,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.15),
                  width: 0.8,
                ),
                borderRadius: BorderRadius.circular(14.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                onChanged: locationController.filterLocations,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    Icons.search,
                    color: theme.colorScheme.onSurface.withOpacity(0.55),
                  ),
                  hintText: "Search".tr,
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.45),
                    fontSize: 14,
                  ),
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
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                color: isSelected
                  ? theme.colorScheme.surface.withOpacity(0.08)
                  : theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(14.0),
                              border: Border.all(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outline.withOpacity(0.15),
                                width: isSelected ? 1.4 : 0.9,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: theme.colorScheme.primary.withOpacity(0.12),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.03),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                            ),
                            child: ListTile(
                              title: Text(
                                location,
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              leading: isSelected
                                  ? Icon(
                                      Icons.check_circle,
                                      color: theme.colorScheme.primary,
                                    )
                                  : const Icon(
                                      Icons.radio_button_unchecked,
                                      color: Color(0xFF9E9E9E),
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
