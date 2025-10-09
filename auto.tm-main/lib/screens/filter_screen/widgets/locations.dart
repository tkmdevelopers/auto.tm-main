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

// Unified, simplified location selector just for FilterScreen.
// Mirrors design/behavior of post screen location selector, without origin branching.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:auto_tm/screens/filter_screen/controller/filter_controller.dart';

class FilterLocationController extends GetxController {
  final RxList<String> allLocations = <String>[].obs;
  final RxList<String> filteredLocations = <String>[].obs;
  final searchText = ''.obs;
  final selectedLocation = ''.obs; // store last tapped (mirrors filterController.location)

  @override
  void onInit() {
    super.onInit();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/json/city.json');
      final List<dynamic> data = json.decode(jsonStr) as List<dynamic>;
      final cities = data
          .map((e) => e is Map && e['name'] != null ? e['name'].toString() : null)
          .whereType<String>()
          .toList();
      cities.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      allLocations.assignAll(cities);
      filteredLocations.assignAll(cities);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Failed to load locations: $e');
        debugPrint('$st');
      }
    }
  }

  void filterLocations(String query) {
    searchText.value = query;
    if (query.trim().isEmpty) {
      filteredLocations.assignAll(allLocations);
      return;
    }
    final q = query.toLowerCase();
    filteredLocations.assignAll(allLocations.where((c) => c.toLowerCase().contains(q)));
  }

  void select(String loc) => selectedLocation.value = loc;
  void resetSearch() { searchText.value = ''; filteredLocations.assignAll(allLocations); }
}

class SLocations extends StatelessWidget {
  SLocations({super.key});

  final FilterLocationController locationController = Get.put(FilterLocationController());
  final FilterController filterController = Get.find<FilterController>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final isCupertino = theme.platform == TargetPlatform.iOS;

    // Preselect currently chosen location if any
    if (filterController.location.value.isNotEmpty &&
        locationController.selectedLocation.isEmpty) {
      locationController.selectedLocation.value = filterController.location.value;
    }

    final searchField = isCupertino
        ? _CupertinoSearchBar(
            onChanged: locationController.filterLocations,
            onClear: locationController.resetSearch,
          )
        : _MaterialSearchBar(
            onChanged: locationController.filterLocations,
            onClear: locationController.resetSearch,
          );

    final isLocal = filterController.selectedCountry.value == 'Local';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header + search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded, color: onSurface),
                    onPressed: () {
                      _safePop(context);
                    },
                    tooltip: 'Back',
                  ),
                  Expanded(
                    child: Text(
                      'Location'.tr,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: searchField,
            ),
            if (!isLocal)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Text(
                  'City selection available only for Local region'.tr,
                  style: TextStyle(color: onSurface.withOpacity(0.6), fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              )
            else
              Expanded(
                child: Obx(() {
                  final locations = locationController.filteredLocations;
                  if (locations.isEmpty) {
                    return Center(
                      child: Text('No locations found'.tr,
                          style: TextStyle(color: onSurface.withOpacity(0.6))),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                    itemCount: locations.length,
                    itemBuilder: (context, index) {
                      final city = locations[index];
                      final isSelected = locationController.selectedLocation.value == city;
                      return _LocationTile(
                        label: city,
                        isSelected: isSelected,
                        onTap: () {
                          // Prevent redundant work if already selected and we came back accidentally
                          if (filterController.location.value == city) {
                            _safePop(context);
                            return;
                          }
                          locationController.select(city);
                          filterController.location.value = city;
                          // Optionally trigger an automatic search refresh (comment out if not desired)
                          // filterController.searchProducts();
                          _safePop(context);
                        },
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

  void _safePop(BuildContext context) {
    // First try Navigator directly (most reliable)
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    // Fallback to Get if navigator stack not recognized
    if (Get.key.currentState?.canPop() == true) {
      Get.back();
      return;
    }
    // As an absolute fallback, do nothing (already at root). Could log in debug.
  }
}

class _LocationTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _LocationTile({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;
    final borderColor = isSelected ? primary : theme.colorScheme.outline.withOpacity(0.4);
    final bg = isSelected ? primary.withOpacity(0.08) : theme.colorScheme.surfaceVariant.withOpacity(0.25);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
              ),
              child: Row(
                children: [
                  Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, color: isSelected ? primary : onSurface.withOpacity(0.55), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: onSurface,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ),
      ),
    );
  }
}

class _MaterialSearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  const _MaterialSearchBar({required this.onChanged, required this.onClear});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
      ),
      child: TextField(
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search'.tr,
          prefixIcon: Icon(Icons.search, color: theme.colorScheme.onSurface.withOpacity(0.55)),
          suffixIcon: IconButton(
            icon: Icon(Icons.close_rounded, color: theme.colorScheme.onSurface.withOpacity(0.5)),
            onPressed: onClear,
            tooltip: 'Clear'.tr,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
        ),
      ),
    );
  }
}

class _CupertinoSearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  const _CupertinoSearchBar({required this.onChanged, required this.onClear});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Icon(Icons.search, color: theme.colorScheme.onSurface.withOpacity(0.55)),
          const SizedBox(width: 4),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              cursorColor: theme.colorScheme.primary,
              decoration: InputDecoration(
                hintText: 'Search'.tr,
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, color: theme.colorScheme.onSurface.withOpacity(0.55), size: 20),
            onPressed: onClear,
            splashRadius: 18,
            tooltip: 'Clear'.tr,
          ),
        ],
      ),
    );
  }
}
