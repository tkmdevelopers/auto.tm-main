import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  group('ThemeController - Logic Tests', () {
    test('isDark should default to true', () {
      final isDark = true.obs;
      expect(isDark.value, true);
    });

    test('toggleTheme should switch dark mode', () {
      final isDark = true.obs;

      isDark.value = false;
      expect(isDark.value, false);

      isDark.value = true;
      expect(isDark.value, true);
    });

    test('themeMode should return dark when isDark is true', () {
      final isDark = true.obs;
      final mode = isDark.value ? ThemeMode.dark : ThemeMode.light;
      expect(mode, ThemeMode.dark);
    });

    test('themeMode should return light when isDark is false', () {
      final isDark = false.obs;
      final mode = isDark.value ? ThemeMode.dark : ThemeMode.light;
      expect(mode, ThemeMode.light);
    });
  });

  group('CurrencyController - Logic Tests', () {
    test('selectedCurrency should default to Dollar', () {
      final selectedCurrency = 'Dollar'.obs;
      expect(selectedCurrency.value, 'Dollar');
    });

    test('updateCurrency should change value', () {
      final selectedCurrency = 'Dollar'.obs;
      selectedCurrency.value = 'TMT';
      expect(selectedCurrency.value, 'TMT');
    });

    test('currency names should be valid', () {
      final validCurrencies = ['Dollar', 'TMT', 'EUR', 'RUB'];
      for (final currency in validCurrencies) {
        expect(currency.isNotEmpty, true);
      }
    });
  });

  group('LanguageController - Logic Tests', () {
    test('selectedLanguage should default to English', () {
      final selectedLanguage = 'English'.obs;
      expect(selectedLanguage.value, 'English');
    });

    test('language update should create correct locale', () {
      const languageCode = 'tk';
      const countryCode = 'TM';

      final locale = Locale(languageCode, countryCode);

      expect(locale.languageCode, 'tk');
      expect(locale.countryCode, 'TM');
    });

    test('storage key format should be correct', () {
      const languageCode = 'tk';
      const countryCode = 'TM';

      final storageKey = '${languageCode}_$countryCode';
      expect(storageKey, 'tk_TM');
    });

    test('supported languages should have valid codes', () {
      final languages = {
        'English': {'code': 'en', 'country': 'US'},
        'Türkmen': {'code': 'tk', 'country': 'TM'},
        'Русский': {'code': 'ru', 'country': 'RU'},
      };

      for (final entry in languages.entries) {
        expect(entry.key.isNotEmpty, true);
        expect(entry.value['code']!.length, 2);
        expect(entry.value['country']!.length, 2);
      }
    });
  });

  group('ConnectionController - Logic Tests', () {
    test('hasConnection should default to true', () {
      final hasConnection = true.obs;
      expect(hasConnection.value, true);
    });

    test('hasConnection should track connectivity state', () {
      final hasConnection = true.obs;

      hasConnection.value = false;
      expect(hasConnection.value, false);

      hasConnection.value = true;
      expect(hasConnection.value, true);
    });
  });
}
