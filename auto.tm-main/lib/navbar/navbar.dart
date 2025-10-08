import 'package:auto_tm/navbar/controller/navbar_controller.dart';
import 'package:auto_tm/navbar/widgets/bottom_nav_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BottomNavView extends StatelessWidget {
  BottomNavView({super.key});

  final BottomNavController controller = Get.put(BottomNavController());

  @override
  Widget build(BuildContext context) {
        final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Obx(() => controller.pages[controller.selectedIndex.value]),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: Obx(
          () => BottomNavigationBar(
            elevation: 20,
            type: BottomNavigationBarType.fixed,
            currentIndex: controller.selectedIndex.value,
            onTap: controller.changeIndex,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            backgroundColor: theme.bottomNavigationBarTheme.backgroundColor,
            items: [
              buildBottomNavItem(
                selectedIconPath: controller.selectedIcons[0],
                  unselectedIconPath: controller.unSelectedIcons[0],
                  label: controller.labels[0], color: theme.bottomNavigationBarTheme.selectedItemColor, unColor: theme.bottomNavigationBarTheme.unselectedItemColor,
              ), 
              buildBottomNavItem(
                selectedIconPath: controller.selectedIcons[1],
                  unselectedIconPath: controller.unSelectedIcons[1],
                  label: controller.labels[1],
                  color: theme.bottomNavigationBarTheme.selectedItemColor, unColor: theme.bottomNavigationBarTheme.unselectedItemColor,
              ),
              buildBottomNavItem(
                selectedIconPath: controller.selectedIcons[2],
                  unselectedIconPath: controller.unSelectedIcons[2],
                  label: controller.labels[2],
                  color: theme.bottomNavigationBarTheme.selectedItemColor, unColor: theme.bottomNavigationBarTheme.unselectedItemColor,
              ),
              buildBottomNavItem(
                selectedIconPath: controller.selectedIcons[3],
                  unselectedIconPath: controller.unSelectedIcons[3],
                  label: controller.labels[3],
                  color: theme.bottomNavigationBarTheme.selectedItemColor, unColor: theme.bottomNavigationBarTheme.unselectedItemColor,
              ),
              buildBottomNavItem(
                selectedIconPath: controller.selectedIcons[4],
                  unselectedIconPath: controller.unSelectedIcons[4],
                  label: controller.labels[4],
                  color: theme.bottomNavigationBarTheme.selectedItemColor, unColor: theme.bottomNavigationBarTheme.unselectedItemColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}