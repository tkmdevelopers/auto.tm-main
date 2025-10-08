// Clean implementation of location selection screen below.
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:auto_tm/utils/navigation_utils.dart';

import '../controller/post_controller.dart';

class LocationController extends GetxController {
  final RxList<String> allLocations = <String>[].obs;
  final RxList<String> filteredLocations = <String>[].obs;
  final searchText = ''.obs;
  final selectedLocation = ''.obs;

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
          .map(
            (e) => e is Map && e['name'] != null ? e['name'].toString() : null,
          )
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
    filteredLocations.assignAll(
      allLocations.where((c) => c.toLowerCase().contains(q)),
    );
  }

  void selectLocation(String loc) {
    selectedLocation.value = loc;
  }

  void resetSearch() {
    searchText.value = '';
    filteredLocations.assignAll(allLocations);
  }
}

class SLocationSelection extends StatelessWidget {
  SLocationSelection({super.key});

  final LocationController locationController = Get.put(LocationController());
  final PostController controller = Get.find<PostController>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCupertino = theme.platform == TargetPlatform.iOS;
    final onSurface = theme.colorScheme.onSurface;

    void safePop([String? result]) =>
        NavigationUtils.safePop(context, result: result);

    final searchField = isCupertino
        ? _CupertinoSearchBar(
            onChanged: locationController.filterLocations,
            onClear: locationController.resetSearch,
          )
        : _MaterialSearchBar(
            onChanged: locationController.filterLocations,
            onClear: locationController.resetSearch,
          );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              elevation: 0,
              backgroundColor: theme.scaffoldBackgroundColor,
              centerTitle: false,
              titleSpacing: 16,
              title: Text(
                'Location'.tr,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(64),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: searchField,
                ),
              ),
            ),
            Obx(() {
              final locations = locationController.filteredLocations;
              if (locations.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'No locations found'.tr,
                      style: TextStyle(color: onSurface.withValues(alpha: 0.6)),
                    ),
                  ),
                );
              }
              final width = MediaQuery.of(context).size.width;
              final useGrid = width > 600;
              if (useGrid) {
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 4.5,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final city = locations[index];
                      return _LocationTile(
                        label: city,
                        isSelected:
                            locationController.selectedLocation.value == city,
                        onTap: () {
                          if (!NavigationUtils.throttle('location_select'))
                            return;
                          locationController.selectLocation(city);
                          // Return selected city so caller can handle focus reset centrally
                          FocusScope.of(context).unfocus();
                          safePop(city);
                        },
                      );
                    }, childCount: locations.length),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final loc = locations[index];
                  return _LocationTile(
                    label: loc,
                    isSelected:
                        locationController.selectedLocation.value == loc,
                    onTap: () {
                      if (!NavigationUtils.throttle('location_select')) return;
                      locationController.selectLocation(loc);
                      FocusScope.of(context).unfocus();
                      safePop(loc);
                    },
                  );
                }, childCount: locations.length),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _LocationTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _LocationTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;
    final borderColor = isSelected
        ? primary
        : theme.colorScheme.outline.withValues(alpha: 0.4);
    final bg = isSelected
        ? primary.withValues(alpha: 0.08)
        : theme.colorScheme.surfaceVariant.withValues(alpha: 0.3);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: isSelected
                      ? primary
                      : onSurface.withValues(alpha: 0.5),
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: onSurface,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
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
        color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: TextField(
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search'.tr,
          prefixIcon: Icon(
            Icons.search,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              Icons.close_rounded,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            onPressed: onClear,
            tooltip: 'Clear'.tr,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 14,
          ),
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
        color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Icon(
            Icons.search,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
          ),
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
            icon: Icon(
              Icons.close_rounded,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              size: 20,
            ),
            onPressed: onClear,
            splashRadius: 18,
            tooltip: 'Clear'.tr,
          ),
        ],
      ),
    );
  }
}
