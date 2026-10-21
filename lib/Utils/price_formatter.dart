import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:graba2z/Controllers/country_controller.dart';
import 'package:graba2z/Controllers/language_controller.dart';

/// True when the app language is Arabic and [LanguageController] is ready.
/// Never throws — falls back to false.
bool _isArabicUi({bool? arabic}) {
  if (arabic != null) return arabic;
  if (Get.isRegistered<LanguageController>()) {
    return Get.find<LanguageController>().isArabic;
  }
  return false;
}

/// Formats an AED amount for DISPLAY in a country's currency.
///
/// displayed = aedAmount × rate. Always 2 decimals.
/// English: symbol-first, e.g. "SAR 1,299.00".
/// Arabic: symbol-last with the Arabic symbol, e.g. "1,299.00 ر.س".
/// For AE (rate 1.0) English output is identical to before.
String formatPrice(double aedAmount,
    {required double rate, required String symbol, bool? arabic}) {
  final r = rate > 0 ? rate : 1.0;
  final converted = aedAmount * r;
  final formatted = NumberFormat('#,##0.00', 'en_US').format(converted);
  if (_isArabicUi(arabic: arabic)) {
    return '$formatted $symbol';
  }
  return '$symbol $formatted';
}

/// Display helper that reads the selected country from [CountryController].
/// In Arabic mode uses the Arabic currency symbol, placed after the amount.
/// Falls back to AED @ 1.0 when the controller isn't registered — never crashes.
String formatPriceForSelected(double aedAmount, {bool? arabic}) {
  final ar = _isArabicUi(arabic: arabic);
  if (Get.isRegistered<CountryController>()) {
    final c = Get.find<CountryController>();
    return formatPrice(aedAmount,
        rate: c.effectiveRate,
        symbol: ar ? c.localizedCurrencySymbol : c.currencySymbol,
        arabic: ar);
  }
  return formatPrice(aedAmount,
      rate: 1.0, symbol: ar ? 'د.إ' : 'AED', arabic: ar);
}

/// Currency symbol of the selected country. Falls back to 'AED'.
/// Returns the Arabic symbol (e.g. "ر.س") when the UI language is Arabic.
String currencySymbolForSelected({bool? arabic}) {
  final ar = _isArabicUi(arabic: arabic);
  if (Get.isRegistered<CountryController>()) {
    final c = Get.find<CountryController>();
    return ar ? c.localizedCurrencySymbol : c.currencySymbol;
  }
  return ar ? 'د.إ' : 'AED';
}
