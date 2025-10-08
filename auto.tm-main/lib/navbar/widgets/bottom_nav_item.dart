import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

BottomNavigationBarItem buildBottomNavItem({
  required String unselectedIconPath,
  required String selectedIconPath,
  required String label,
  required Color? color,
  required Color? unColor,
}) {
  return BottomNavigationBarItem(
    icon: SvgPicture.asset(
      unselectedIconPath,
      width: 24,
      height: 24,
      colorFilter: ColorFilter.mode(unColor!, BlendMode.srcIn),
    ),
    activeIcon: SvgPicture.asset(
      selectedIconPath,
      width: 24,
      height: 24,
      colorFilter: ColorFilter.mode(color!, BlendMode.srcIn),
    ),
    label: label,
  );
}