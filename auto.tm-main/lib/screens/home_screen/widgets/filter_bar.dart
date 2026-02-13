import 'package:auto_tm/utils/color_extensions.dart';
// widgets/filter_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../../ui_components/images.dart';
import '../../filter_screen/filter_screen.dart';

class FilterBar extends StatelessWidget {
  const FilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: 'Open filters'.tr,
      child: Material(
        color: theme.colorScheme.surface,
        elevation: 2,
        shadowColor: theme.shadowColor.opacityCompat(0.25),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Get.to(() => FilterScreen()),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            height: 45,
            width: double.infinity,
            child: Row(
              children: [
                SvgPicture.asset(
                  AppImages.car,
                  height: 22,
                  width: 22,
                  colorFilter: ColorFilter.mode(
                    theme.colorScheme.onSurface,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "${'Brand'.tr} ${'Model'.tr} ${'Country'.tr}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: theme.colorScheme.onSurface.opacityCompat(0.85),
                    ),
                  ),
                ),
                // Visual separator (optional subtle line)
                Container(
                  height: 20,
                  width: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  color: theme.colorScheme.onSurface.opacityCompat(0.15),
                ),
                SvgPicture.asset(
                  AppImages.filter,
                  height: 20,
                  width: 20,
                  colorFilter: ColorFilter.mode(
                    theme.colorScheme.onSurface,
                    BlendMode.srcIn,
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
