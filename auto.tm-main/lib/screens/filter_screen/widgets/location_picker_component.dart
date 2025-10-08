import 'package:auto_tm/screens/filter_screen/controller/filter_controller.dart';
import 'package:auto_tm/ui_components/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// class CountryPicker extends StatelessWidget {
//   final FilterController controller = Get.put(FilterController());

//   CountryPicker({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     return Obx(() => Container(
//       width: double.infinity,
//           decoration: BoxDecoration(
//             color: theme.colorScheme.primaryContainer,
//             borderRadius: BorderRadius.circular(16),
//             border: Border.all(color: AppColors.textTertiaryColor, width: 0.4),
//           ),
//           padding: EdgeInsets.all(2),
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: ['Local', 'Dubai', 'China'].map((filter) {
//               bool isSelected = controller.selectedCountry.value == filter;
//               return GestureDetector(
//                 onTap: () => controller.selectLocation(filter),
//                 child: Container(
//                   // width: double.infinity,
//                   width: MediaQuery.of(context).size.width*0.28,
//                   padding: EdgeInsets.symmetric(vertical: 2, horizontal: 16),
//                   decoration: BoxDecoration(
//                     color: isSelected ? Color(0xFFC4C4C4) : Colors.transparent,
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Text(
//                     filter,
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       color: isSelected ? AppColors.textSecondaryColor : theme.colorScheme.primary,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ),
//               );
//             }).toList(),
//           ),
//         ));
//   }
// }

class CountryPicker extends StatelessWidget {
  CountryPicker({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final FilterController controller = Get.find<FilterController>();

    final Map<String, String> filterOptions = {
      'Local': 'Local',
      'Dubai': 'Dubai',
      'China': 'China',
    };

    return Obx(
      () => Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.textTertiaryColor, width: 0.5),
        ),
        padding: const EdgeInsets.all(2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: filterOptions.entries.map((entry) { 
            final String englishValue = entry.key;
            final String translationKey = entry.value; 

            bool isSelected = controller.selectedCountry.value == englishValue; 

            return GestureDetector(
              onTap: () {
                controller.selectLocation(englishValue);
                controller.searchProducts();
              },
              child: Container(
                width: MediaQuery.of(context).size.width * 0.28,
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 16),
                decoration: BoxDecoration(
                  color: isSelected ? theme.colorScheme.onSurface.withOpacity(0.08) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  translationKey.tr, 
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurface.withOpacity(0.60),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}