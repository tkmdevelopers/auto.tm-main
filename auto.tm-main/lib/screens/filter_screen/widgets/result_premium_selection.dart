import 'package:auto_tm/screens/filter_screen/controller/filter_controller.dart';
import 'package:auto_tm/screens/filter_screen/filter_screen.dart';
import 'package:auto_tm/screens/filter_screen/widgets/locations.dart';
import 'package:auto_tm/screens/home_screen/controller/premium_controller.dart';
import 'package:auto_tm/ui_components/colors.dart';
import 'package:auto_tm/ui_components/images.dart';
import 'package:auto_tm/utils/key.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

class ResultPremiumSelection extends StatelessWidget {
  ResultPremiumSelection({super.key});

  final PremiumController premiumController = Get.put(PremiumController());
  final FilterController controller = Get.find<FilterController>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 40,
      child: Obx(
        () => ListView(
          physics: BouncingScrollPhysics(),
          shrinkWrap: true,
          scrollDirection: Axis.horizontal,
          children: [
            GestureDetector(
              onTap: () {
                // Get.back();
                Get.off(() => FilterScreen());
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: 4,
                  horizontal: 10,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.textTertiaryColor,
                    width: 0.4,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: theme.colorScheme.surface,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      AppImages.filter,
                      width: 16,
                      height: 16,
                      colorFilter: ColorFilter.mode(
                        theme.colorScheme.onSurface,
                        BlendMode.srcIn,
                      ),
                      // color: theme.colorScheme.primary,
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Text(
                      'Filter'.tr,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 2,
            ),
            if(controller.selectedCountry.value == 'Local')
            _buildLocationButton(context),
            // GestureDetector(
            //   onTap: () {
            //     Get.to(() => SLocations());
            //   },
            //   child: Container(
            //     alignment: Alignment.center,
            //     padding: EdgeInsets.symmetric(
            //       vertical: 4,
            //       horizontal: 10,
            //     ),
            //     decoration: BoxDecoration(
            //       border: Border.all(
            //         color: AppColors.textTertiaryColor,
            //         width: 0.3,
            //       ),
            //       borderRadius: BorderRadius.circular(12),
            //       color: theme.colorScheme.secondaryContainer,
            //     ),
            //     child: Text(
            //       'Location'.tr,
            //       style: TextStyle(
            //         fontSize: 14,
            //         fontWeight: FontWeight.w500,
            //         color: theme.colorScheme.primary,
            //       ),
            //     ),
            //   ),
            // ),
            SizedBox(
              width: 2,
            ),
            Row(
              children: premiumController.subscriptions.map((option) {
                return GestureDetector(
                  onTap: () {
                    // if (isSelected) {
                    //   premiumController.selectedPremiumTypes
                    //       .remove(option['type']);
                    // } else {
                    //   premiumController.selectedPremiumTypes.add(option['type']);
                    // }
                    // filterController
                    //     .applyFilters();
                  },
                  child: Obx(
                    () {
                      final bool isSelected = controller.premium.contains(option.uuid);
                      return Container(
                        margin: EdgeInsets.symmetric(horizontal: 2,),
                      // Obx to react to changes in selectedPremiumTypes
                      padding:
                          const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
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
                        // color: AppColors.primaryColor,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min, // Wrap content
                        children: [
                          if(option.path != '')
                          Image.network('${ApiKey.ip}${option.path}', height: 22, width: 22,)
                          else Icon(Icons.ac_unit_rounded),
                          const SizedBox(width: 12),
                          // Text(
                          //   option.price.toString(), // Your premium type name
                          //   style: AppStyles.f14w4.copyWith(
                          //     color: isSelected
                          //         ? AppColors.primaryColor
                          //         : theme.colorScheme.onSurface,
                          //   ),
                          // ),
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
                    },
                  ),
                );
              }).toList(),
            ),
            SizedBox(width: 2,),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationButton(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
            onTap: () {
              Get.to(() => SLocations());
            },
            child: Container(
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(
                vertical: 4,
                horizontal: 10,
              ),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.textTertiaryColor,
                  width: 0.3,
                ),
                borderRadius: BorderRadius.circular(12),
                color: theme.colorScheme.surface,
              ),
              child: Text(
                'Location'.tr,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          );
  }
}
