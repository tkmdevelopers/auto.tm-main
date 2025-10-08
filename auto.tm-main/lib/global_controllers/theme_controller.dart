import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ThemeController extends GetxController {
  final GetStorage _box = GetStorage();
  final String _themeKey = 'is_dark_mode';

  RxBool isDark = true.obs;

  @override
  void onInit() {
    super.onInit();
    _loadThemeFromStorage();
    Get.changeThemeMode(themeMode.value);
  }

  Rx<ThemeMode> get themeMode => isDark.value ? ThemeMode.dark.obs : ThemeMode.light.obs;


  void _loadThemeFromStorage() {
    final bool? storedIsDark = _box.read<bool>(_themeKey);
    isDark.value = storedIsDark ?? true;
  }

  void toggleTheme(bool value) {
    isDark.value = value;
    _box.write(_themeKey, value);
    Get.changeThemeMode(isDark.value ? ThemeMode.dark : ThemeMode.light);
  }

  void setDarkTheme() {
    isDark.value = true;
    _box.write(_themeKey, true);
    Get.changeThemeMode(ThemeMode.dark);
  }

  void setLightTheme() {
    isDark.value = false;
    _box.write(_themeKey, false);
    Get.changeThemeMode(ThemeMode.light);
  }
}