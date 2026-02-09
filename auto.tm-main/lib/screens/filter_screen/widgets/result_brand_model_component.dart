import 'package:auto_tm/screens/filter_screen/controller/filter_controller.dart';
import 'package:auto_tm/screens/filter_screen/widgets/brand_selection.dart';
import 'package:auto_tm/screens/filter_screen/widgets/model_selection.dart';
import 'package:auto_tm/ui_components/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ResultBrandModelComponent extends StatelessWidget {
  ResultBrandModelComponent({super.key});

  final FilterController controller = Get.find<FilterController>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: AppColors.textTertiaryColor,
      width: 0.5,
    ),
    color: theme.colorScheme.surface,
  ),
  height: 124, // Ensure container has enough height for expansion
  child: Column(
    children: [
      /// Brand Section
      Expanded(
        child: Obx(
          () => GestureDetector(
            behavior: HitTestBehavior.opaque, // Ensures the whole area is tappable
            onTap: () { // Navigate preserving origin; mark results viewed
              final isResults = Get.currentRoute.contains('FilterResultPage');
              controller.hasViewedResults.value = controller.hasViewedResults.value || isResults;
              Get.to(() => BrandSelection(origin: isResults ? 'results' : (controller.hasViewedResults.value ? 'filter' : 'initial')));
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center, // Vertically center text
                  children: [
                    Text(
                      'Brand'.tr,
                      style: TextStyle(
                        fontSize: controller.selectedBrandName.value != '' ? 12 : 14,
                        fontWeight: controller.selectedBrandName.value != ''
                            ? FontWeight.w400
                            : FontWeight.w500,
            color: controller.selectedBrandName.value != ''
              ? AppColors.textTertiaryColor
              : theme.colorScheme.onSurface,
                      ),
                    ),
                    if (controller.selectedBrandName.value != '')
                      Text(
                        controller.selectedBrandName.value,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                  ],
                ),
                if (controller.selectedBrandName.value != '')
                  IconButton(
                    onPressed: () {
                      controller.selectedBrandName.value = '';
                      controller.selectedBrandUuid.value = '';
                      controller.selectedModelName.value = '';
                      controller.selectedModelUuid.value = '';
                      controller.searchProducts();
                    },
                    icon: Icon(
                      Icons.cancel_outlined,
                      color: AppColors.textTertiaryColor,
                      size: 16,
                    ),
                  )
                else
                  Icon(
                    Icons.add_circle_outline_rounded,
                    color: AppColors.textTertiaryColor,
                    size: 16,
                  ),
              ],
            ),
          ),
        ),
      ),

      const SizedBox(height: 12),
      Divider(color: AppColors.textTertiaryColor, height: 0.5),
      const SizedBox(height: 12),

      /// Model Section
      Expanded(
        child: Obx(
          () => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (controller.selectedBrandUuid.value != '') {
                final isResults = Get.currentRoute.contains('FilterResultPage'); // preserve origin
                controller.hasViewedResults.value = controller.hasViewedResults.value || isResults;
                Get.to(() => ModelSelection(
                      brandUuid: controller.selectedBrandUuid.value,
                      brandName: controller.selectedBrandName.value,
                      origin: isResults ? 'results' : (controller.hasViewedResults.value ? 'filter' : 'initial'),
                    ));
              } else {
                final isResults = Get.currentRoute.contains('FilterResultPage'); // preserve origin
                controller.hasViewedResults.value = controller.hasViewedResults.value || isResults;
                Get.to(() => BrandSelection(origin: isResults ? 'results' : (controller.hasViewedResults.value ? 'filter' : 'initial')));
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Model'.tr,
                      style: TextStyle(
                        fontSize: controller.selectedModelName.value != '' ? 12 : 14,
                        fontWeight: controller.selectedModelName.value != ''
                            ? FontWeight.w400
                            : FontWeight.w500,
            color: controller.selectedModelName.value != ''
              ? AppColors.textTertiaryColor
              : theme.colorScheme.onSurface,
                      ),
                    ),
                    if (controller.selectedModelName.value != '')
                      Text(
                        controller.selectedModelName.value,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                  ],
                ),
                if (controller.selectedModelName.value != '')
                  IconButton(
                    onPressed: () {
                      controller.selectedModelName.value = '';
                      controller.selectedModelUuid.value = '';
                      controller.searchProducts();
                    },
                    icon: Icon(
                      Icons.cancel_outlined,
                      color: AppColors.textTertiaryColor,
                      size: 16,
                    ),
                  )
                else
                  Icon(
                    Icons.add_circle_outline_rounded,
                    color: AppColors.textTertiaryColor,
                    size: 16,
                  ),
              ],
            ),
          ),
        ),
      ),
    ],
  ),
)
;
  }
}
