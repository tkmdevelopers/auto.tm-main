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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final FilterController controller = Get.find<FilterController>();
    final PremiumController premiumController = Get.put(PremiumController());

    return Scaffold(
      appBar: AppBar(
        elevation: 4,
        backgroundColor: theme.appBarTheme.backgroundColor,
        surfaceTintColor: theme.appBarTheme.backgroundColor,
        title: Text(
          "Filter".tr,
          style: TextStyle(
            color: theme.colorScheme.onSurface, // Uses theme color
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        automaticallyImplyLeading: true,
        actions: [
          TextButton(
            onPressed: () {
              controller.clearFilters();
            },
            child: Text(
              "Clear".tr,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              controller.searchProducts();
              Get.off(() => FilterResultPage());
            },
            child: Text(
              "Done".tr,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ), // Red for accent
          ),
        ],
      ),
      backgroundColor: theme.colorScheme.surface,
      body: Obx(
        () => ListView(
          padding: const EdgeInsets.all(16),
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
            Obx(
              () => Column(
                spacing: 8.0,
                children: [
                  if (controller.selectedBrand.value != '')
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Brand'.tr,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.textTertiaryColor,
                                ),
                              ),
                              Text(
                                controller.selectedBrand.value,
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () {
                              controller.selectedBrand.value = '';
                              controller.selectedBrandUuid.value = '';
                              controller.selectedModel.value = '';
                              controller.selectedModelUuid.value = '';
                            },
                            icon: Icon(
                              Icons.cancel_outlined,
                              color: AppColors.textTertiaryColor,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (controller.selectedModel.value != '')
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Divider(
                        height: 0.5,
                        color: AppColors.textTertiaryColor,
                      ),
                    ),
                  if (controller.selectedModel.value != '')
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Model'.tr,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.textTertiaryColor,
                                ),
                              ),
                              Text(
                                controller.selectedModel.value,
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () {
                              controller.selectedModel.value = '';
                              controller.selectedModelUuid.value = '';
                            },
                            icon: Icon(
                              Icons.cancel_outlined,
                              color: AppColors.textTertiaryColor,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Divider(height: 0.5, color: AppColors.textTertiaryColor),
            const SizedBox(height: 16),
            _buildSelectorTile(
              "Location".tr,
              controller.location.value.isEmpty
                  ? (controller.selectedCountry.value.isEmpty
                      ? 'Any'.tr
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
                    'CVT'.tr,
                    'Dual-clutch'.tr,
                  ],
                  controller.transmission,
                );
              },
              context,
            ),
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Engine power'.tr,
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
                          controller: controller.enginepowerController,
                          hintText: '0',
                          type: TextInputType.numberWithOptions(),
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 0.5, color: AppColors.textTertiaryColor),
              ],
            ),
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Milleage'.tr,
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
                          controller: controller.milleageController,
                          hintText: '0',
                          type: TextInputType.numberWithOptions(),
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 0.5, color: AppColors.textTertiaryColor),
              ],
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Min year'.tr,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 6),
                    InkWell(
                      onTap: () => controller.showDatePickerAndroidMin(context),
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.33,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.textFieldBorderColor,
                          ),
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Obx(() {
                          final value = controller.minYear.value;
                          return Text(
                            value.isEmpty ? 'Any'.tr : value,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: value.isEmpty
                                  ? AppColors.textTertiaryColor
                                  : theme.colorScheme.onSurface,
                            ),
                          );
                        }),
                      ),
                    ),
                    SizedBox(height: 14),
                  ],
                ),
                Text(
                  '-',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 40,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Max year'.tr,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 6),
                    InkWell(
                      onTap: () => controller.showDatePickerAndroidMax(context),
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.33,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.textFieldBorderColor,
                          ),
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Obx(() {
                          final value = controller.maxYear.value;
                          return Text(
                            value.isEmpty ? 'Any'.tr : value,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: value.isEmpty
                                  ? AppColors.textTertiaryColor
                                  : theme.colorScheme.onSurface,
                            ),
                          );
                        }),
                      ),
                    ),
                    SizedBox(height: 14),
                  ],
                ),
              ],
            ),
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
            SizedBox(height: 24),
            Text("Premium".tr, style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children:
                  premiumController.subscriptions.map((option) {
                    return GestureDetector(
                      onTap: () {
                        controller.togglePremium(option.uuid);
                        controller.searchProducts();
                      },
                      child: Obx(() {
                        final bool isSelected = controller.premium.contains(
                          option.uuid,
                        );
                        return Container(
                          margin: EdgeInsets.symmetric(horizontal: 2),
                          padding: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 10,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color:
                                  isSelected
                                      ? theme.colorScheme.onSurface
                                      : AppColors.textTertiaryColor,
                              width: 0.3,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color:
                                isSelected
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
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                        );
                      }),
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String title, BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        Get.to(() => BrandSelection());
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
                      onPressed: () => Get.back(),
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
                          Get.back();
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
                                    Get.back();
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
}
