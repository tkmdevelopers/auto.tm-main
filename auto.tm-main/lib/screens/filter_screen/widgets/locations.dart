// import 'package:auto_tm/screens/filter_screen/controller/filter_controller.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// // Mock GetX controller
// class LocationController extends GetxController {
//   final selectedLocation = Rx<String?>(null); // Use Rx for reactive updates
//   final locations = <String>[
//     'Ashgabat',
//     'Ahal',
//     'Balkan',
//     'Mary',
//     'Lebap',
//     'Dashoguz',
//     // 'New York, USA',
//     // 'Los Angeles, USA',
//     // 'Chicago, USA',
//     // 'Houston, USA',
//     // 'Phoenix, USA',
//     // 'Philadelphia, USA',
//     // 'San Antonio, USA',
//     // 'San Diego, USA',
//     // 'Dallas, USA',
//     // 'San Jose, USA',
//     // 'Austin, USA',
//     // 'Jacksonville, USA',
//     // 'Fort Worth, USA',
//     // 'Columbus, USA',
//     // 'San Francisco, USA',
//     // 'Las Vegas, USA',
//     // 'Seattle, USA',
//     // 'Denver, USA',
//     // 'Washington, D.C., USA',
//     // 'Boston, USA',
//   ];

//   void selectLocation(String location) {
//     selectedLocation.value = location; // Update the Rx variable
//     print('Selected Location: ${selectedLocation.value}');
//   }

//   String? getSelectedLocation() {
//     return selectedLocation.value;
//   }
// }

// class SLocations extends StatelessWidget {
//   final LocationController locationController = Get.put(LocationController());
//   final FilterController filterController = Get.put(FilterController());

//   SLocations({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               Color(0xFF222222), // Black
//               Color(0xFF4A148C), // Deep Purple
//               Color(0xFF000000), // Black
//             ],
//           ),
//         ),
//         padding: const EdgeInsets.all(16.0),
//         child: Center(
//           child: SizedBox(
//             width: double.infinity,
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: <Widget>[
//                 Text(
//                   'Select Location',
//                   style: TextStyle(
//                     fontSize: 30.0,
//                     fontWeight: FontWeight.bold,
//                     foreground: Paint()..shader = const LinearGradient(
//                       colors: <Color>[
//                         Colors.blue,
//                         Colors.purple,
//                       ],
//                     ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0))
//                   ),
//                 ),
//                 const SizedBox(height: 10.0),
//                 const Text(
//                   'Choose a location from the list below.',
//                   style: TextStyle(
//                     fontSize: 16.0,
//                     color: Colors.grey,
//                   ),
//                 ),
//                 Obx(() {
//                   final selectedLoc = locationController.selectedLocation.value;
//                   return selectedLoc != null
//                       ? Padding(
//                           padding: const EdgeInsets.only(top: 16.0),
//                           child: Container(
//                             padding: const EdgeInsets.all(12.0),
//                             decoration: BoxDecoration(
//                               color: Colors.black.withOpacity(0.2),
//                               borderRadius: BorderRadius.circular(8.0),
//                               border: Border.all(color: Colors.purple.withOpacity(0.3)),
//                             ),
//                             child: Text(
//                               'Selected: $selectedLoc',
//                               style: const TextStyle(
//                                 fontSize: 16.0,
//                                 color: Colors.purpleAccent,
//                               ),
//                             ),
//                           ),
//                         )
//                       : const SizedBox.shrink();
//                 }),
//                 const SizedBox(height: 20.0),
//                 SizedBox(
//                   height: 400,
//                   child: Scrollbar(
//                     child: ListView.builder(
//                       itemCount: locationController.locations.length,
//                       itemBuilder: (context, index) {
//                         final location = locationController.locations[index];
//                         return Padding(
//                           padding: const EdgeInsets.symmetric(vertical: 8.0),
//                           child: Obx((){
//                             final isSelected = locationController.selectedLocation.value == location;
//                             return AnimatedContainer(
//                               duration: const Duration(milliseconds: 300),
//                               curve: Curves.easeInOut,
//                               decoration: BoxDecoration(
//                                 color: Colors.white.withOpacity(0.05),
//                                 borderRadius: BorderRadius.circular(12.0),
//                                 border: Border.all(
//                                   color: isSelected? Colors.purple.withOpacity(0.3) : Colors.white.withOpacity(0.1),
//                                   width: isSelected? 2: 1
//                                 ),
//                                 boxShadow: isSelected? [
//                                   BoxShadow(
//                                     color: Colors.purple.withOpacity(0.2),
//                                     spreadRadius: 2,
//                                     blurRadius: 10,
//                                     offset: const Offset(0, 3), // changes position of shadow
//                                   ),
//                                 ] : [],
//                                 // transform: isSelected? Matrix4.identity().scaled(1.02) : Matrix4.identity()
//                               ),
//                               child: ListTile(
//                                 title: Text(
//                                   location,
//                                   style: const TextStyle(
//                                     fontSize: 18.0,
//                                     color: Colors.white,
//                                   ),
//                                 ),
//                                 onTap: () {
//                                   locationController.selectLocation(location);
//                                 },
//                               ),
//                             );
//                           })
//                         );
//                       },
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 20.0),
//                 ElevatedButton(
//                   onPressed: () {
//                     Get.back();
//                   },
//                   style: ElevatedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(30.0),
//                     ),
//                     backgroundColor: Colors.purple.shade500.withOpacity(0.9),
//                     foregroundColor: Colors.white,
//                     shadowColor: Colors.purple.shade500.withOpacity(0.3),
//                     elevation: 8,
//                   ),
//                   child: const Text(
//                     'Go Back',
//                     style: TextStyle(
//                       fontSize: 18.0,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'dart:convert';

import 'package:auto_tm/screens/filter_screen/controller/filter_controller.dart';
import 'package:auto_tm/ui_components/colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

// Controller
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
      final String response = await rootBundle.loadString('assets/json/city.json');
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
      filteredLocations.assignAll(allLocations.where((location) {
        return location.toLowerCase().contains(lowerCaseQuery);
      }).toList());
    }
  }

  void resetSearch() {
    searchText.value = '';
    filteredLocations.assignAll(allLocations);
  }
}

// Screen
class SLocations extends StatelessWidget {
  final LocationController locationController = Get.put(LocationController());
  final FilterController filterController = Get.put(FilterController());

  SLocations({super.key});

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
              "Reset",
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
                border:
                    Border.all(color: AppColors.textTertiaryColor, width: 0.5),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: TextField(
                onChanged: locationController.filterLocations,
                style: TextStyle(color: theme.colorScheme.primary),
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
                                style:
                                    TextStyle(color: theme.colorScheme.primary),
                              ),
                              leading: isSelected
                                  ? Icon(Icons.radio_button_checked,
                                      color: theme.primaryColor)
                                  : const Icon(Icons.radio_button_off,
                                      color: AppColors.textTertiaryColor),
                              onTap: () {
                                locationController.selectLocation(location);
                                filterController.location.value = location;
                                filterController.searchProducts();
                                Get.back();
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
