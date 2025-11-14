import 'package:auto_tm/screens/post_details_screen/controller/post_details_controller.dart';
import 'package:auto_tm/ui_components/colors.dart';
import 'package:auto_tm/ui_components/styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Footer with price display and call button
class PriceCallFooter extends StatelessWidget {
  final PostDetailsController controller;
  final ThemeData theme;

  const PriceCallFooter({
    super.key,
    required this.controller,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: theme.bottomNavigationBarTheme.backgroundColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Price section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${'Price'.tr}:',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Obx(() {
                  final post = controller.post;
                  final price = post?.price;
                  final currency = post?.currency;

                  final priceText = (price != null && currency != null)
                      ? '${price.toStringAsFixed(0)}$currency'
                      : 'N/A';

                  return Text(
                    priceText,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.notificationColor,
                    ),
                  );
                }),
              ],
            ),
            // Call button
            ElevatedButton(
              onPressed: () {
                final phoneNumber = controller.post?.phoneNumber;
                if (phoneNumber != null &&
                    phoneNumber.isNotEmpty &&
                    phoneNumber != '+993') {
                  controller.makePhoneCall(phoneNumber);
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(80, 50),
                backgroundColor: AppColors.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              ),
              child: Text(
                'Call'.tr,
                style: AppStyles.f18w4.copyWith(
                  color: AppColors.scaffoldColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
