import 'package:auto_tm/screens/filter_screen/controller/filter_controller.dart';
import 'package:auto_tm/screens/filter_screen/widgets/brand_selection.dart';
import 'package:auto_tm/screens/filter_screen/widgets/model_selection.dart';
import 'package:auto_tm/ui_components/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ResultBrandModelComponent extends StatelessWidget {
  ResultBrandModelComponent({super.key});

  final FilterController controller = Get.put(FilterController());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: AppColors.textTertiaryColor,
      width: 0.3,
    ),
    color: theme.colorScheme.secondaryContainer,
  ),
  height: 124, // Ensure container has enough height for expansion
  child: Column(
    children: [
      /// Brand Section
      Expanded(
        child: Obx(
          () => GestureDetector(
            behavior: HitTestBehavior.opaque, // Ensures the whole area is tappable
            onTap: () => Get.off(() => BrandSelection()),
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
                        fontSize: controller.selectedBrand.value != '' ? 12 : 14,
                        fontWeight: controller.selectedBrand.value != ''
                            ? FontWeight.w400
                            : FontWeight.w500,
                        color: controller.selectedBrand.value != ''
                            ? AppColors.textTertiaryColor
                            : theme.colorScheme.primary,
                      ),
                    ),
                    if (controller.selectedBrand.value != '')
                      Text(
                        controller.selectedBrand.value,
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                  ],
                ),
                if (controller.selectedBrand.value != '')
                  IconButton(
                    onPressed: () {
                      controller.selectedBrand.value = '';
                      controller.selectedBrandUuid.value = '';
                      controller.selectedModel.value = '';
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
                Get.off(
                  () => ModelSelection(
                    brandUuid: controller.selectedBrandUuid.value,
                    brandName: controller.selectedBrand.value,
                  ),
                );
              } else {
                Get.off(() => BrandSelection());
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
                        fontSize: controller.selectedModel.value != '' ? 12 : 14,
                        fontWeight: controller.selectedModel.value != ''
                            ? FontWeight.w400
                            : FontWeight.w500,
                        color: controller.selectedModel.value != ''
                            ? AppColors.textTertiaryColor
                            : theme.colorScheme.primary,
                      ),
                    ),
                    if (controller.selectedModel.value != '')
                      Text(
                        controller.selectedModel.value,
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                  ],
                ),
                if (controller.selectedModel.value != '')
                  IconButton(
                    onPressed: () {
                      controller.selectedModel.value = '';
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
