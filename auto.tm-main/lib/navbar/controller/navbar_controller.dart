import 'package:auto_tm/screens/blog_screen/blog_screen.dart';
import 'package:auto_tm/screens/favorites_screen/favorites_screen.dart';
import 'package:auto_tm/screens/home_screen/controller/home_controller.dart';
import 'package:auto_tm/screens/home_screen/home_screen.dart';
import 'package:auto_tm/screens/post_screen/post_check_page.dart';
import 'package:auto_tm/screens/profile_screen/profile_check_page.dart';
import 'package:auto_tm/ui_components/images.dart';
import 'package:auto_tm/services/token_service/token_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BottomNavController extends GetxController {
  var selectedIndex = 0.obs;
  final tokenService = Get.put(TokenService());
  
  void changeIndex(int index) {
    // Prevent reopening or navigating if already on the selected tab
    if (selectedIndex.value == index) {
      if (index == 0) {
        // Only scroll to top for home tab if reselected
        final homeController = Get.find<HomeController>();
        homeController.scrollToTop();
      }
      // Do nothing for other tabs if reselected
      return;
    }

    // Handle navigation and token checks only when changing tab
    // Protected tabs: Post (2) & Profile (4)
    if (index == 2 || index == 4) {
      final token = tokenService.getToken();
      if (token == null || token.isEmpty) {
        Get.toNamed('/register');
        return; // Don't change selectedIndex if redirecting
      }
    }

    // Only update the index if we're not redirecting to register
    selectedIndex.value = index;
  }

  // New order: Home (0), Favourites (1), Post (2 - center), Blog (3), Profile (4)
  final List<Widget> pages = [
    HomeScreen(),
    MyFavouritesScreen(),
    PostCheckPage(),
    BlogScreen(),
    ProfileCheckPage(),
  ];

  final List selectedIcons = [
    AppImages.searchF,     // home
    AppImages.favouriteF,  // favourites
    AppImages.postF,       // post (center)
    AppImages.chatF,       // blog
    AppImages.profileO,    // profile
  ];
  final List unSelectedIcons = [
    AppImages.searchO,
    AppImages.favouriteO,
    AppImages.postO,
    AppImages.chatO,
    AppImages.profileO,
  ];
  final List<String> labels = ["home", "fav", "post", "blog", "profile"];
}
