import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleService {
  static const _langKey = 'app_language';

  static final ValueNotifier<Locale> localeNotifier =
      ValueNotifier(const Locale('ar'));

  static Locale get locale => localeNotifier.value;
  static bool get isArabic => locale.languageCode == 'ar';

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_langKey);
    if (stored != null) {
      localeNotifier.value = Locale(stored);
    } else {
      localeNotifier.value = const Locale('ar');
    }
  }

  static Future<void> toggle() async {
    final next = isArabic ? const Locale('en') : const Locale('ar');
    await setLocale(next);
  }

  static Future<void> setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, locale.languageCode);
    localeNotifier.value = locale;
  }
}
