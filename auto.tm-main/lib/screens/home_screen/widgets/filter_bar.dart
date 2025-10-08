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
    return GestureDetector(
      onTap: () => Get.to(() => FilterScreen()),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: theme.colorScheme.onSurface,
          boxShadow: [BoxShadow(color: theme.shadowColor, blurRadius: 5)],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        height: 45,
        width: double.infinity,
        child: Row(
          children: [
            SvgPicture.asset(
              AppImages.car,
              height: 22,
              width: 22,
              colorFilter: ColorFilter.mode(theme.colorScheme.surface, BlendMode.srcIn),
              // color: theme.iconTheme.color,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "${'Brand'.tr} ${'Model'.tr} ${'Country'.tr}",
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: theme.iconTheme.color,
                ),
              ),
            ),
            const VerticalDivider(indent: 10, endIndent: 10),
            SvgPicture.asset(
              AppImages.filter,
              height: 20,
              width: 20,
              colorFilter: ColorFilter.mode(theme.colorScheme.onSurface, BlendMode.srcIn),
              // color: theme.iconTheme.color,
            ),
          ],
        ),
      ),
    );
  }
}
