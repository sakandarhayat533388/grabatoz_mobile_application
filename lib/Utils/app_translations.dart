import 'package:get/get.dart';

/// GetX translations for English + Arabic.
///
/// Phase 1 ships the core chrome keys. More screen keys will be added in
/// Phase 2 as screens are migrated to `.tr`.
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': {
          'language': 'Language',
          'english': 'English',
          'arabic': 'Arabic',
          'select_language': 'Select Language',
          'language_hint': 'App language will change immediately',
          'country_currency': 'Country / Currency',
          'settings': 'Settings',
          'home': 'Home',
          'categories': 'Categories',
          'cart': 'Cart',
          'profile': 'Profile',
          'search': 'Search',
          'checkout': 'Checkout',
          'continue': 'Continue',
          'cancel': 'Cancel',
          'save': 'Save',
          'done': 'Done',
          'loading': 'Loading...',
          'retry': 'Retry',
          'ok': 'OK',
        },
        'ar_AE': {
          'language': 'اللغة',
          'english': 'الإنجليزية',
          'arabic': 'العربية',
          'select_language': 'اختر اللغة',
          'language_hint': 'سيتم تغيير لغة التطبيق فوراً',
          'country_currency': 'الدولة / العملة',
          'settings': 'الإعدادات',
          'home': 'الرئيسية',
          'categories': 'الفئات',
          'cart': 'السلة',
          'profile': 'الحساب',
          'search': 'بحث',
          'checkout': 'الدفع',
          'continue': 'متابعة',
          'cancel': 'إلغاء',
          'save': 'حفظ',
          'done': 'تم',
          'loading': 'جارٍ التحميل...',
          'retry': 'إعادة المحاولة',
          'ok': 'حسناً',
        },
      };
}
