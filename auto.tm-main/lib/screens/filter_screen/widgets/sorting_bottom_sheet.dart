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
    Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      // Убираем padding из контейнера, добавим его в Column
      child: Column(
        mainAxisSize: MainAxisSize.min, // Занимаем только необходимое пространство
        children: [
          // Шапка BottomSheet с заголовком и кнопкой закрытия
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order by:'.tr, // Заголовок
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: AppColors.textTertiaryColor, size: 20,),
                  onPressed: () => Get.back(), // Закрыть BottomSheet
                ),
              ],
            ),
          ),
          // const Divider(height: 1, thickness: 0.5), // Разделитель
          Flexible( // Используем Flexible, чтобы BottomSheet не выходил за границы экрана
            child: ListView.builder(
              shrinkWrap: true, // Важно, чтобы ListView занимал только нужное место внутри Flexible/Column
              physics: const ClampingScrollPhysics(), // Ограничиваем прокрутку, если контента много
              itemCount: sortOptions.length,
              itemBuilder: (context, index) {
                final optionData = sortOptions[index];
                final String apiValue = optionData['value']!;
                final String displayKey = optionData['displayKey']!;

                return Obx(() { // Obx для отслеживания изменений selectedSortOption
                  return Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                        title: Text(
                          displayKey.tr, // Переведенный текст для отображения
                          style: TextStyle(
                            fontSize: 16,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        trailing: Radio<String>(
                          value: apiValue,
                          groupValue: searchController.selectedSortOption.value, // Берем значение из контроллера
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              searchController.updateSortOption(newValue); // Обновляем контроллер
                              Get.back(); // Закрываем BottomSheet после выбора
                            }
                          },
                          activeColor: AppColors.primaryColor, // Цвет выбранной радиокнопки
                        ),
                        onTap: () {
                          // Позволяем выбрать, нажав на весь ListTile
                          searchController.updateSortOption(apiValue);
                          Get.back();
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: const Divider(height: 1, thickness: 0.5, color: AppColors.textTertiaryColor,),
                      ), // Разделитель после каждого пункта
                    ],
                  );
                });
              },
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom), // Отступ снизу для безопасной зоны
        ],
      ),
    ),
    backgroundColor: Colors.transparent, // Прозрачный фон для закругленных углов
    isScrollControlled: true, // Позволяет BottomSheet быть высоким, если нужно
  );
}