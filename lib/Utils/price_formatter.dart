import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:graba2z/Controllers/country_controller.dart';

/// Formats an AED amount for DISPLAY in a country's currency.
///
/// displayed = aedAmount × rate. Always 2 decimals, English symbol-first,
/// e.g. "SAR 1,299.00". For AE (rate 1.0) output is identical to before.
String formatPrice(double aedAmount,
    {required double rate, required String symbol}) {
  final r = rate > 0 ? rate : 1.0;
  final converted = aedAmount * r;
  final formatted = NumberFormat('#,##0.00', 'en_US').format(converted);
  return '$symbol $formatted';
}

/// Display helper that reads the selected country from [CountryController].
/// Falls back to AED @ 1.0 when the controller isn't registered — never crashes.
String formatPriceForSelected(double aedAmount) {
  if (Get.isRegistered<CountryController>()) {
    final c = Get.find<CountryController>();
    return formatPrice(aedAmount,
        rate: c.effectiveRate, symbol: c.currencySymbol);
  }
  return formatPrice(aedAmount, rate: 1.0, symbol: 'AED');
}

/// Currency symbol of the selected country. Falls back to 'AED'.
String currencySymbolForSelected() {
  if (Get.isRegistered<CountryController>()) {
    return Get.find<CountryController>().currencySymbol;
  }
  return 'AED';
}
