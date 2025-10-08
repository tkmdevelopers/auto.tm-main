import 'package:auto_tm/screens/filter_screen/controller/filter_controller.dart';
import 'package:auto_tm/ui_components/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void showSortOptionsBottomSheet(
  BuildContext context,
  // Здесь мы не передаем title, т.к. он фиксированный ("Order by:")
  // Мы не передаем selectedValue напрямую, а используем SearchController
) {
  final theme = Theme.of(context);
  final FilterController searchController = Get.find<FilterController>();

  // Опции сортировки в соответствии со скриншотом.
  // 'value' - это объединенный ключ для API, 'displayKey' - для перевода.
  final List<Map<String, String>> sortOptions = [
    // {'value': 'relevant_desc', 'displayKey': 'Relevance'},
    {'value': 'createdAt_desc', 'displayKey': 'Date of placement'}, // Дате размещения (по убыванию)
    {'value': 'price_asc', 'displayKey': 'Price: lowest'}, // Возрастанию цены
    {'value': 'price_desc', 'displayKey': 'Price: highest'}, // Убыванию цены
    {'value': 'year_desc', 'displayKey': 'Year: newest'}, // Году: новее
    {'value': 'year_asc', 'displayKey': 'Year: oldest'}, // Году: старше
    {'value': 'milleage_asc', 'displayKey': 'Mileage'}, // Пробегу (предполагаем, что по возрастанию для "меньше пробег")
    // {'value': 'name_asc', 'displayKey': 'By name'}, // По названию
    // {'value': 'unique_desc', 'displayKey': 'Uniqueness'}, // Уникальности (если есть такое поле)
    // {'value': 'cost_estimate_desc', 'displayKey': 'Cost estimate'}, // Оценке стоимости (если есть такое поле)
    // {'value': 'owners_first_desc', 'displayKey': 'Owners first'}, // Сначала от собственников (если есть такое поле)
  ];

  Get.bottomSheet(
    SafeArea(
      top: false,
      child: Material(
        color: theme.colorScheme.surface,
        elevation: 12,
        shadowColor: Colors.black.withOpacity(0.3),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            // Drag handle
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
                    'Order by:'.tr,
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
                physics: const ClampingScrollPhysics(),
                itemCount: sortOptions.length,
                separatorBuilder: (_, __) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(
                    height: 1,
                    thickness: 0.5,
                    color: AppColors.textTertiaryColor.withOpacity(0.6),
                  ),
                ),
                itemBuilder: (context, index) {
                  final optionData = sortOptions[index];
                  final String apiValue = optionData['value']!;
                  final String displayKey = optionData['displayKey']!;
                  return Obx(() {
                    final bool selected =
                        searchController.selectedSortOption.value == apiValue;
                    return InkWell(
                      onTap: () {
                        searchController.updateSortOption(apiValue);
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
                                displayKey.tr,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      selected ? FontWeight.w600 : FontWeight.w400,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            Radio<String>(
                              value: apiValue,
                              groupValue: searchController
                                  .selectedSortOption.value,
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  searchController.updateSortOption(newValue);
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