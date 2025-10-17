import 'package:auto_tm/screens/filter_screen/controller/filter_controller.dart';
import 'package:auto_tm/screens/filter_screen/widgets/filter_result_picker.dart';
import 'package:auto_tm/screens/filter_screen/widgets/location_picker_component.dart';
import 'package:auto_tm/screens/filter_screen/widgets/result_brand_model_component.dart';
import 'package:auto_tm/screens/filter_screen/widgets/result_premium_selection.dart';
import 'package:auto_tm/screens/filter_screen/widgets/sorting_bottom_sheet.dart';
import 'package:auto_tm/screens/home_screen/widgets/post_item.dart';
import 'package:auto_tm/navbar/navbar.dart';
// import 'package:auto_tm/screens/home_screen/home_screen.dart'; // Avoid direct navigation to raw HomeScreen to preserve BottomNavView
import 'package:auto_tm/navbar/controller/navbar_controller.dart';
import 'package:auto_tm/screens/home_screen/widgets/post_shimmer.dart';
import 'package:auto_tm/screens/profile_screen/controller/profile_controller.dart';
import 'package:auto_tm/ui_components/images.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

class FilterResultPage extends StatelessWidget {
  FilterResultPage({super.key});

  // final FilterController controller = Get.put(FilterController());
  final FilterController controller = Get.find<FilterController>();
  // Reuse existing ProfileController singleton across app.
  final ProfileController profileController = ProfileController.ensure();

  @override
  Widget build(BuildContext context) {
    profileController.fetchProfile;
    final theme = Theme.of(context);
    void _exitToHome() {
      controller.clearFilters(includeBrandModel: true);
      // Always rebuild nav root to avoid popping into intermediate selection screens
      Get.offAll(() => BottomNavView());
      // After nav root builds, ensure index 0
      if (Get.isRegistered<BottomNavController>()) {
        Get.find<BottomNavController>().changeIndex(0);
      }
    }

    return WillPopScope(
      onWillPop: () async {
        _exitToHome();
        return false; // we handled navigation
      },
      child: Scaffold(
      appBar: AppBar(
        elevation: 4,
        backgroundColor: theme.appBarTheme.backgroundColor,
        surfaceTintColor: theme.appBarTheme.backgroundColor,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.colorScheme.onSurface),
          tooltip: 'Back',
          onPressed: _exitToHome,
        ),
        title: Text(
          'Filter Results'.tr,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: InkWell(
              onTap: () => showSortOptionsBottomSheet(context),
              child: SvgPicture.asset(
                AppImages.sort,
                colorFilter: ColorFilter.mode(
                  theme.colorScheme.onSurface,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          // if (controller.selectedBrandUuid.value != '' &&
          //     profileController.box.read('USER_ID') != '')
          //   Padding(
          //     padding: const EdgeInsets.only(right: 10.0),
          //     child: InkWell(
          //       onTap: () {
          //         if ((profileController.profile.value != null &&
          //             !profileController.profile.value!.brandUuid!.contains(
          //               controller.selectedBrandUuid.value,
          //             ))) {
          //           controller.subscribeToBrand();
          //           profileController.fetchProfile();
          //         } else {
          //           controller.unSubscribeFromBrand();
          //           profileController.fetchProfile();
          //         }
          //       },
          //       child: Obx(
          //         () => SvgPicture.asset(
          //           (profileController.profile.value != null &&
          //                   profileController.profile.value!.brandUuid!
          //                       .contains(controller.selectedBrandUuid.value))
          //               ? AppImages.car
          //               : AppImages.subscribe,
          //           colorFilter: ColorFilter.mode(
          //             theme.colorScheme.onSurface,
          //             BlendMode.srcIn,
          //           ),
          //           // color: theme.colorScheme.primary,
          //         ),
          //       ),
          //     ),
          //   ),
        ],
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      // body: SafeArea(
      //   child: ListView(
      //     padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      //     children: [
      //       CountryPicker(),
      //       SizedBox(
      //         height: 8,
      //       ),
      //       FilterResultPicker(),
      //       SizedBox(
      //         height: 8,
      //       ),
      //       ResultBrandModelComponent(),
      //       SizedBox(
      //         height: 16,
      //       ),
      //       ResultPremiumSelection(),
      //       SizedBox(
      //         height: 16,
      //       ),
      //       Obx(() {
      //         if (controller.isSearchLoading.value) {
      //           return
      //           Column(
      //             children: [
      //               PostItemShimmer(),
      //               PostItemShimmer(),
      //               PostItemShimmer(),
      //             ],
      //           );
      //         } else if (controller.searchResults.isNotEmpty) {
      //           return Column(
      //             children: controller.searchResults.map((post) {
      //               return PostItem(
      //                 uuid: post.uuid,
      //                 price: post.price,
      //                 model: post.model,
      //                 brand: post.brand,
      //                 photoPath: post.photoPath,
      //                 year: post.year,
      //                 milleage: post.milleage,
      //                 currency: post.currency,
      //                 createdAt: post.createdAt,
      //                 subscription: post.subscription,
      //               );
      //             }).toList(),
      //           );
      //         }
      //         return SizedBox.shrink();
      //       }),
      //     ],
      //   ),
      // ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await controller.searchProducts();
          },
          child: ListView(
            controller: controller.scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              Obx(() {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CountryPicker(),
                    SizedBox(height: 8),
                    FilterResultPicker(),
                    SizedBox(height: 8),
                    ResultBrandModelComponent(),
                    SizedBox(height: 16),
                    ResultPremiumSelection(),
                    SizedBox(height: 16),
                    if (controller.isSearchLoading.value &&
                        controller.searchResults.isEmpty)
                      Column(
                        children: [
                          PostItemShimmer(),
                          PostItemShimmer(),
                          PostItemShimmer(),
                        ],
                      )
                    else if (controller.searchResults.isNotEmpty)
                      ...controller.searchResults.map(
                        (post) => PostItem(
                          uuid: post.uuid,
                          price: post.price,
                          model: post.model,
                          brand: post.brand,
                          photoPath: post.photoPath,
                          year: post.year,
                          milleage: post.milleage,
                          currency: post.currency,
                          createdAt: post.createdAt,
                          subscription: post.subscription,
                          location: post.location,
                          region: post.region, // ensure region (personalInfo.region) is displayed
                        ),
                      ),
                    if (controller.isSearchLoading.value &&
                        controller.searchResults.isNotEmpty)
                      PostItemShimmer(),
                  ],
                );
              }),
            ],
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton.small(
        onPressed: () {
          controller.scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        },
  foregroundColor: theme.colorScheme.surface,
  backgroundColor: theme.colorScheme.surface,
        shape: const CircleBorder(),
        child: Icon(
          Icons.arrow_upward_outlined,
          color: theme.colorScheme.onSurface,
        ),
      ),
    ));
  }
}
