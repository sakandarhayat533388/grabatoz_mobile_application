import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide language selection (English / Arabic).
///
/// The choice is persisted in SharedPreferences and applied via
/// `Get.updateLocale`, which also flips the layout to RTL for Arabic.
class LanguageController extends GetxController {
  static const String _prefsKey = 'app_language';

  static const String englishCode = 'en';
  static const String arabicCode = 'ar';

  final RxString currentLang = englishCode.obs;

  bool get isArabic => currentLang.value == arabicCode;

  bool get isEnglish => !isArabic;

  Locale get locale =>
      isArabic ? const Locale('ar', 'AE') : const Locale('en', 'US');

  /// Reads the saved language (if any) and applies it. Safe to call
  /// before the controller is registered via [loadLanguageCode].
  Future<void> loadSaved() async {
    final code = await loadLanguageCode();
    currentLang.value = code;
    Get.updateLocale(locale);
  }

  /// Persists [code] ('en' / 'ar') and applies it immediately.
  Future<void> setLanguage(String code) async {
    final normalized = code == arabicCode ? arabicCode : englishCode;
    currentLang.value = normalized;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, normalized);
    } catch (_) {}
    Get.updateLocale(locale);
  }

  /// Static helper for pre-runApp init (before GetX registration).
  static Future<String> loadLanguageCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      if (saved == arabicCode) return arabicCode;
    } catch (_) {}
    return englishCode;
  }
}
