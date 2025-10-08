import 'dart:ui';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class LanguageController extends GetxController {
  final GetStorage storage = GetStorage();

  var selectedLanguage = 'English'.obs;

  void updateLanguage(
    String language,
    String languageCode,
    String countryCode,
  ) {
    selectedLanguage.value = language;
    storage.write('lang_selected', selectedLanguage.value);

    Locale locale = Locale(languageCode, countryCode);
    Get.updateLocale(locale);
    storage.write('language', '${languageCode}_$countryCode');
  }
}
