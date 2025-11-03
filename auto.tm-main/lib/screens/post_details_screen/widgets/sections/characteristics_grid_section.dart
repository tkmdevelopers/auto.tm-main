import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:auto_tm/screens/post_details_screen/model/post_model.dart';
import 'package:auto_tm/ui_components/styles.dart';
import 'package:auto_tm/ui_components/colors.dart';
import 'package:auto_tm/ui_components/images.dart';

class CharacteristicsGridSection extends StatelessWidget {
  final Post? post;
  final ThemeData theme;
  const CharacteristicsGridSection({
    super.key,
    required this.post,
    required this.theme,
  });

  bool _isNonEmpty(String? v) => v != null && v.trim().isNotEmpty;
  bool _isPositive(num? v) => v != null && v > 0;

  @override
  Widget build(BuildContext context) {
    if (post == null) return const SizedBox.shrink();

    final regionRaw = post!.region.trim();
    final regionLower = regionRaw.toLowerCase();
    final locRaw = post!.location;
    String? displayLocation;
    if (regionLower == 'local') {
      if (_isNonEmpty(locRaw)) displayLocation = locRaw.trim();
    } else if (regionLower == 'uae' || regionLower == 'china') {
      displayLocation = regionRaw;
    }

    final entries =
        <_CharacteristicEntry>[
              _CharacteristicEntry(
                icon: AppImages.enginePower,
                label: 'Engine power'.tr,
                value: _isPositive(post!.enginePower)
                    ? '${post!.enginePower.toStringAsFixed(0)} L'
                    : null,
              ),
              _CharacteristicEntry(
                icon: AppImages.transmission,
                label: 'Transmission'.tr,
                value: _isNonEmpty(post!.transmission)
                    ? post!.transmission.tr
                    : null,
              ),
              _CharacteristicEntry(
                icon: AppImages.year,
                label: 'Year'.tr,
                value: _isPositive(post!.year)
                    ? '${post!.year.toStringAsFixed(0)} y.'.tr
                    : null,
              ),
              _CharacteristicEntry(
                icon: AppImages.milleage,
                label: 'Milleage'.tr,
                value: _isPositive(post!.milleage)
                    ? '${post!.milleage.toStringAsFixed(0)} km'.tr
                    : null,
              ),
              _CharacteristicEntry(
                icon: AppImages.carCondition,
                label: 'Car condition'.tr,
                value: _isNonEmpty(post!.condition) ? post!.condition.tr : null,
              ),
              _CharacteristicEntry(
                icon: AppImages.engineType,
                label: 'Engine type'.tr,
                value: _isNonEmpty(post!.engineType)
                    ? post!.engineType.tr
                    : null,
              ),
              _CharacteristicEntry(
                icon: AppImages.vin,
                label: 'VIN',
                value: _isNonEmpty(post!.vinCode) ? post!.vinCode : null,
              ),
              if (displayLocation != null)
                _CharacteristicEntry(
                  icon: AppImages.location,
                  label: 'Location'.tr,
                  value: displayLocation,
                ),
              _CharacteristicEntry(
                icon: AppImages.exchange,
                label: 'Exchange'.tr,
                value: (post!.exchange == true)
                    ? 'post_exchange_possible'.tr
                    : 'post_exchange_not_possible'.tr,
              ),
              _CharacteristicEntry(
                icon: AppImages.credit,
                label: 'Credit'.tr,
                value: (post!.credit == true)
                    ? 'post_credit_available'.tr
                    : 'post_credit_not_available'.tr,
              ),
            ]
            .where(
              (e) =>
                  e.value != null &&
                  e.value!.trim().isNotEmpty &&
                  e.value != '0',
            )
            .toList();

    if (entries.isEmpty) return const SizedBox.shrink();

    final rows = <Widget>[];
    for (int i = 0; i < entries.length; i += 2) {
      final first = entries[i];
      final second = (i + 1) < entries.length ? entries[i + 1] : null;
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildItem(first)),
            const SizedBox(width: 12),
            Expanded(
              child: second != null ? _buildItem(second) : const SizedBox(),
            ),
          ],
        ),
      );
      if (i + 2 < entries.length) rows.add(const SizedBox(height: 10));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: theme.scaffoldBackgroundColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Characteristics'.tr,
            style: AppStyles.f20w5.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: AppColors.textTertiaryColor, height: 0.5),
          const SizedBox(height: 16),
          ...rows,
        ],
      ),
    );
  }

  Widget _buildItem(_CharacteristicEntry e) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SvgPicture.asset(
          e.icon,
          width: 28,
          height: 28,
          colorFilter: ColorFilter.mode(
            theme.colorScheme.onSurfaceVariant,
            BlendMode.srcIn,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${e.label}:',
                style: AppStyles.f16w6.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  overflow: TextOverflow.ellipsis,
                ),
                maxLines: 2,
              ),
              Text(
                e.value ?? '-',
                style: AppStyles.f14w4.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CharacteristicEntry {
  final String icon;
  final String label;
  final String? value;
  _CharacteristicEntry({
    required this.icon,
    required this.label,
    required this.value,
  });
}
