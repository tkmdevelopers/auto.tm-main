import 'package:auto_tm/screens/auth_screens/login_screen/widgets/text_field_text.dart';
import 'package:auto_tm/screens/filter_screen/controller/filter_controller.dart';
import 'package:auto_tm/screens/filter_screen/widgets/brand_selection.dart';
import 'package:auto_tm/screens/filter_screen/widgets/filter_picker.dart';
import 'package:auto_tm/screens/filter_screen/widgets/filter_result_page.dart';
import 'package:auto_tm/screens/filter_screen/widgets/location_picker_component.dart';
import 'package:auto_tm/screens/filter_screen/widgets/locations.dart';
import 'package:auto_tm/screens/home_screen/controller/premium_controller.dart';
import 'package:auto_tm/ui_components/colors.dart';
import 'package:auto_tm/utils/key.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FilterScreen extends StatelessWidget {
  FilterScreen({super.key});

  void _goToResults(FilterController controller) {
    controller.searchProducts();
    controller.hasViewedResults.value = true; // mark results viewed
    // Replace with fresh results page (no transition to avoid flicker / layout flash)
    Get.off(
      () => FilterResultPage(),
      transition: Transition.noTransition,
      duration: Duration.zero,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final FilterController controller = Get.find<FilterController>();
    final PremiumController premiumController = Get.put(PremiumController());

    return WillPopScope(
      onWillPop: () async {
        _goToResults(controller);
        return false; // prevent default pop
      },
  child: Scaffold(
      extendBody: false,
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        elevation: 4,
        backgroundColor: theme.appBarTheme.backgroundColor,
        surfaceTintColor: theme.appBarTheme.backgroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.colorScheme.onSurface),
          onPressed: () => _goToResults(controller),
          tooltip: 'Back',
        ),
        title: Text(
          "Filter".tr,
          style: TextStyle(
            color: theme.colorScheme.onSurface, // Uses theme color
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        automaticallyImplyLeading: false,
        actions: const [],
      ),
      backgroundColor: theme.colorScheme.surface,
       body: Obx(() {
        final active = controller.activeFilterCount;
        return Stack(
          children: [
            // Main scrollable content
            Column(
              children: [
                if (active > 0)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface, // unified surface
                      border: Border(
                        bottom: BorderSide(
                          color: theme.colorScheme.outlineVariant.withOpacity(.25),
                          width: .6,
                        ),
                      ),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: _buildActiveFilterChips(controller, theme)),
                    ),
                  ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 170), // leave space for bar
                    children: [
                      CountryPicker(),
                      const SizedBox(height: 16),
                      Divider(height: 0.5, color: AppColors.textTertiaryColor),
                      const SizedBox(height: 16),
                      FilterPicker(),
                      const SizedBox(height: 16),
                      Divider(height: 0.5, color: AppColors.textTertiaryColor),
                      const SizedBox(height: 16),
                      _buildLabel("Add model and brand".tr, context),
                      const SizedBox(height: 8),
                      _buildBrandModelSummary(theme, controller),
                      Divider(height: 0.5, color: AppColors.textTertiaryColor),
                      const SizedBox(height: 16),
                      _buildSelectorTile(
                        "Location".tr,
                        controller.location.value.isEmpty
                            ? (controller.selectedCountry.value.isEmpty
                                ? 'common_any'.tr
                                : controller.selectedCountry.value)
                            : controller.location.value,
                        () => Get.to(() => SLocations()),
                        context,
                      ),
                      _buildSelectorTile(
                        "Transmission".tr,
                        controller.transmission.value.isEmpty
                            ? 'Select transmission'.tr
                            : controller.transmission.value,
                        () {
                          showOptionsBottomSheet(
                            context,
                            "Transmission".tr,
                            [
                              'Automatic'.tr,
                              'Manual'.tr,
                              'transmission_cvt'.tr,
                              'transmission_dual_clutch'.tr,
                            ],
                            controller.transmission,
                          );
                        },
                        context,
                      ),
                      _buildNumericField(
                        label: 'Engine power'.tr,
                        controller: controller.enginepowerController,
                        theme: theme,
                      ),
                      _buildNumericField(
                        label: 'Milleage'.tr,
                        controller: controller.milleageController,
                        theme: theme,
                      ),
                      const SizedBox(height: 12),
                      _PriceRangeSlider(controller: controller),
                      const SizedBox(height: 12),
                      _YearRangeSlider(controller: controller),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildCheckbox(
                              "Exchange".tr,
                              controller.exchange,
                              theme.colorScheme.onSurface,
                            ),
                          ),
                          Expanded(
                            child: _buildCheckbox(
                              "Credit".tr,
                              controller.credit,
                              theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text("Premium".tr, style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        children: premiumController.subscriptions.map((option) {
                          return GestureDetector(
                            onTap: () {
                              controller.togglePremium(option.uuid);
                              controller.searchProducts();
                            },
                            child: Obx(() {
                              final bool isSelected = controller.premium.contains(option.uuid);
                              return Container(
                                margin: EdgeInsets.symmetric(horizontal: 2),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                  horizontal: 10,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isSelected
                                        ? theme.colorScheme.onSurface
                                        : AppColors.textTertiaryColor,
                                    width: 0.3,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  color: isSelected
                                      ? theme.colorScheme.onSurface.withOpacity(0.07)
                                      : theme.colorScheme.secondaryContainer,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (option.path != '')
                                      Image.network(
                                        '${ApiKey.ip}${option.path}',
                                        height: 22,
                                        width: 22,
                                      )
                                    else
                                      Icon(Icons.ac_unit_rounded),
                                    const SizedBox(width: 12),
                                    Checkbox(
                                      value: isSelected,
                                      onChanged: (bool? value) {
                                        controller.togglePremium(option.uuid);
                                        controller.searchProducts();
                                      },
                                      activeColor: theme.colorScheme.onSurface,
                                      checkColor: Colors.white,
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ],
                                ),
                              );
                            }),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
            // Overlay action bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: theme.colorScheme.outlineVariant.withOpacity(.25),
                      width: 0.7,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      if (active > 0)
                        TextButton(
                          onPressed: () => controller.clearFilters(includeBrandModel: true),
                          child: Text(
          (active > 0
            ? 'filter_clear_all_count'.trParams({'count': active.toString()})
            : 'filter_clear_all'.tr),
                            style: TextStyle(color: theme.colorScheme.onSurface),
                          ),
                        ),
                      Spacer(),
                      ElevatedButton(
                        onPressed: controller.isSearchLoading.value
                            ? null
                            : () {
                                controller.searchProducts();
                                _goToResults(controller);
                              },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          foregroundColor: theme.colorScheme.onSurface,
                          backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(.3),
                          elevation: 0,
                        ),
                        child: controller.isSearchLoading.value
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text('Show Results'.tr, style: TextStyle(color: theme.colorScheme.onSurface)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    ));
  }

  Widget _buildLabel(String title, BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        final filterController = Get.find<FilterController>();
        final origin = filterController.hasViewedResults.value ? 'filter' : 'initial';
        Get.to(() => BrandSelection(origin: origin));
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
                fontSize: 16,
              ),
            ),
            const Icon(Icons.add_circle_outline, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectorTile(
    String title,
    String value,
    void Function() onTap,
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
              fontSize: 16,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(color: AppColors.textTertiaryColor),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textTertiaryColor,
              ),
            ],
          ),
          onTap: onTap,
        ),
        const Divider(height: 0.5, color: AppColors.textTertiaryColor),
      ],
    );
  }

  Widget _buildCheckbox(String title, RxBool value, Color color) {
    return Obx(
      () => CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w400,
                      color: color.withOpacity(0.9),
            fontSize: 14,
          ),
        ),
        value: value.value,
        onChanged: (val) => value.value = val ?? false,
        controlAffinity: ListTileControlAffinity.leading,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  void showOptionsBottomSheet(
    BuildContext context,
    String title,
    List<String> options,
    RxString selectedValue,
  ) {
    final theme = Theme.of(context);
    void _safeSheetPop() {
      // Prefer Navigator to close the modal route first if present
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
        return;
      }
      if (Get.key.currentState?.canPop() == true) {
        Get.back();
      }
    }
    Get.bottomSheet(
      SafeArea(
        top: false,
        child: Material(
          color: theme.colorScheme.surface,
          elevation: 12,
          shadowColor: Colors.black.withOpacity(0.25),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.textTertiaryColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: AppColors.textTertiaryColor,
                        size: 20,
                      ),
                      onPressed: _safeSheetPop,
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: options.length,
                  separatorBuilder: (_, __) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(
                      height: 1,
                      thickness: 0.5,
                      color: AppColors.textTertiaryColor.withOpacity(0.6),
                    ),
                  ),
                  itemBuilder: (context, index) {
                    final opt = options[index];
                    return Obx(() {
                      final bool selected = selectedValue.value == opt;
                      return InkWell(
                        onTap: () {
                          selectedValue.value = opt;
                          _safeSheetPop();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          color: selected
                              ? theme.colorScheme.onSurface.withOpacity(0.05)
                              : Colors.transparent,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  opt,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              Radio<String>(
                                value: opt,
                                groupValue: selectedValue.value,
                                onChanged: (val) {
                                  if (val != null) {
                                    selectedValue.value = val;
                                    _safeSheetPop();
                                  }
                                },
                                activeColor: theme.colorScheme.onSurface,
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                        ),
                      );
                    });
                  },
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 4),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.35),
      isScrollControlled: true,
    );
  }

  List<Widget> _buildActiveFilterChips(FilterController c, ThemeData theme) {
    final chips = <Widget>[];
    void add(String label, VoidCallback onRemove) {
      chips.add(Padding(
        padding: const EdgeInsets.only(right: 6),
        child: InputChip(
          label: Text(label, style: TextStyle(fontSize: 12)),
          onDeleted: onRemove,
          visualDensity: VisualDensity.compact,
          deleteIcon: Icon(Icons.close, size: 16),
        ),
      ));
    }
    if (c.selectedBrand.value.isNotEmpty) {
      add('Brand: ${c.selectedBrand.value}', () {
        c.selectedBrand.value=''; c.selectedBrandUuid.value=''; c.selectedModel.value=''; c.selectedModelUuid.value='';
      });
    }
    if (c.selectedModel.value.isNotEmpty) {
      add('Model: ${c.selectedModel.value}', () { c.selectedModel.value=''; c.selectedModelUuid.value=''; });
    }
    if (c.selectedCountry.value != 'Local' || c.location.value.isNotEmpty) {
      add('Region: ${c.selectedCountry.value}${c.location.value.isNotEmpty ? ' / '+c.location.value : ''}', () { c.selectedCountry.value='Local'; c.location.value=''; });
    }
    if (c.transmission.value.isNotEmpty) {
      add('Trans: ${c.transmission.value}', () { c.transmission.value=''; });
    }
    if (c.minYear.value.isNotEmpty || c.maxYear.value.isNotEmpty) {
      add('Year: ${c.minYear.value.isEmpty ? '..' : c.minYear.value}-${c.maxYear.value.isEmpty ? '..' : c.maxYear.value}', () { c.minYear.value=''; c.maxYear.value=''; });
    }
    if (c.enginepowerController.text.isNotEmpty) {
      add('Power ≥ ${c.enginepowerController.text}', () { c.enginepowerController.clear(); });
    }
    if (c.milleageController.text.isNotEmpty) {
      add('Mileage ≤ ${c.milleageController.text}', () { c.milleageController.clear(); });
    }
    if (c.exchange.value) {
      add('Exchange', () { c.exchange.value=false; });
    }
    if (c.credit.value) {
      add('Credit', () { c.credit.value=false; });
    }
    if (c.selectedColor.value.isNotEmpty) {
      add('Color: ${c.selectedColor.value}', () { c.selectedColor.value=''; });
    }
    if (c.premium.isNotEmpty) {
      add('Premium: ${c.premium.length}', () { c.premium.clear(); });
    }
    if (c.condition.value.isNotEmpty && c.condition.value != 'All') {
      add('Cond: ${c.condition.value}', () { c.condition.value='All'; });
    }
    return chips;
  }

  Widget _buildBrandModelSummary(ThemeData theme, FilterController controller) {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (controller.selectedBrand.value.isNotEmpty)
          _inlineKeyValue(theme, 'Brand'.tr, controller.selectedBrand.value, onRemove: () {
            controller.selectedBrand.value=''; controller.selectedBrandUuid.value=''; controller.selectedModel.value=''; controller.selectedModelUuid.value='';
          }),
        if (controller.selectedModel.value.isNotEmpty)
          _inlineKeyValue(theme, 'Model'.tr, controller.selectedModel.value, onRemove: () { controller.selectedModel.value=''; controller.selectedModelUuid.value=''; }),
      ],
    ));
  }

  Widget _inlineKeyValue(ThemeData theme, String label, String value, {VoidCallback? onRemove}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: AppColors.textTertiaryColor)),
                Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface)),
              ],
            ),
          ),
          if (onRemove != null)
            IconButton(
              onPressed: onRemove,
              icon: Icon(Icons.close, size: 18, color: AppColors.textTertiaryColor),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }

  Widget _buildNumericField({required String label, required TextEditingController controller, required ThemeData theme}) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                  fontSize: 16,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: STextField(
                  controller: controller,
                  hintText: '0',
                  type: const TextInputType.numberWithOptions(),
                ),
              ),
            ),
          ],
        ),
        const Divider(height: 0.5, color: AppColors.textTertiaryColor),
      ],
    );
  }
}

class _YearRangeSlider extends StatelessWidget {
  const _YearRangeSlider({required this.controller});
  final FilterController controller;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final rv = controller.yearRange.value;
      final lower = controller.yearLowerBound.value;
      final upper = controller.yearUpperBound.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('filter_year_range'.tr, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
              const SizedBox(width: 8),
              if (rv.start != lower.toDouble() || rv.end != upper.toDouble())
                TextButton(
                  onPressed: () {
                    controller.yearRange.value = RangeValues(lower.toDouble(), upper.toDouble());
                  },
                  child: Text('Reset'.tr, style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
          RangeSlider(
            min: lower.toDouble(),
            max: upper.toDouble(),
            divisions: (upper - lower),
            labels: RangeLabels(rv.start.round().toString(), rv.end.round().toString()),
            values: rv,
            onChanged: (vals) {
              controller.yearRange.value = vals;
            },
            onChangeEnd: (_) {
              // Clear explicit min/max strings if slider is used
              controller.minYear.value = '';
              controller.maxYear.value = '';
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _yearPill(theme, rv.start.round()),
              _yearPill(theme, rv.end.round()),
            ],
          ),
          const SizedBox(height: 4),
          const Divider(height: 0.5, color: AppColors.textTertiaryColor),
        ],
      );
    });
  }

  Widget _yearPill(ThemeData theme, int year) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(.4), width: 0.6),
      ),
      child: Text(
        year.toString(),
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface),
      ),
    );
  }
}

class _PriceRangeSlider extends StatelessWidget {
  const _PriceRangeSlider({required this.controller});
  final FilterController controller;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final rv = controller.priceRange.value;
      final lower = controller.priceLowerBound.value.toDouble();
      final upper = controller.priceUpperBound.value.toDouble();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('filter_price_range'.tr, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
              const SizedBox(width: 8),
              if (rv.start != lower || rv.end != upper)
                TextButton(
                  onPressed: () {
                    controller.priceRange.value = RangeValues(lower, upper);
                    controller.minPrice.value = null;
                    controller.maxPrice.value = null;
                  },
                  child: Text('Reset'.tr, style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
          RangeSlider(
            min: lower,
            max: upper,
            divisions: (upper - lower).round() ~/ 10000, // coarse divisions to avoid huge count
            labels: RangeLabels(_fmt(rv.start), _fmt(rv.end)),
            values: rv,
            onChanged: (vals) {
              controller.priceRange.value = vals;
            },
            onChangeEnd: (_) {
              controller.minPrice.value = null;
              controller.maxPrice.value = null;
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _pricePill(theme, rv.start),
              _pricePill(theme, rv.end),
            ],
          ),
          const SizedBox(height: 4),
          const Divider(height: 0.5, color: AppColors.textTertiaryColor),
        ],
      );
    });
  }

  String _fmt(double v) {
    final n = v.round();
    if (n >= 1000) {
      final k = (n / 1000).toStringAsFixed(1);
      return k.endsWith('.0') ? k.substring(0, k.length - 2) + 'k' : k + 'k';
    }
    return n.toString();
  }

  Widget _pricePill(ThemeData theme, double value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(.4), width: 0.6),
      ),
      child: Text(
        _fmt(value),
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface),
      ),
    );
  }
}
