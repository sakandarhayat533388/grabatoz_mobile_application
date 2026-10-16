import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:graba2z/Api/Models/country_model.dart';
import 'package:graba2z/Configs/config.dart';
import 'package:graba2z/Controllers/payment_charges_controller.dart';

/// App-wide country / currency selection.
///
/// Fetches `GET /api/countries/public` on launch (5-min cache), persists the
/// selected country code locally (default `AE`), and exposes the effective
/// FX rate + currency symbol used for display-time conversion.
///
/// All money stays in AED — this controller only affects DISPLAY.
class CountryController extends GetxController {
  static const String _prefsKey = 'selected_country_code';
  static const Duration _cacheTtl = Duration(minutes: 5);

  final RxList<Country> countries = <Country>[].obs;
  final Rxn<Country> selectedCountry = Rxn<Country>();
  final RxBool isLoading = false.obs;

  DateTime? _lastFetch;

  /// ISO-2 country code, e.g. "AE". Falls back to "AE".
  String get countryCode => selectedCountry.value?.code ?? 'AE';

  /// Rate to multiply AED amounts by for display. Guarded: never <= 0.
  double get effectiveRate {
    final r = selectedCountry.value?.effectiveRate ?? 1.0;
    return r > 0 ? r : 1.0;
  }

  /// Currency symbol for display, e.g. "AED", "SAR".
  String get currencySymbol => selectedCountry.value?.currencySymbol ?? 'AED';

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = (prefs.getString(_prefsKey) ?? 'AE').toUpperCase();
      await fetchCountries();
      _applySelection(saved);
    } catch (_) {
      _applyFallback();
    }
  }

  void _applySelection(String code) {
    if (countries.isEmpty) {
      _applyFallback();
      return;
    }
    Country? match;
    for (final c in countries) {
      if (c.code.toUpperCase() == code.toUpperCase()) {
        match = c;
        break;
      }
    }
    if (match == null) {
      for (final c in countries) {
        if (c.isDefault) {
          match = c;
          break;
        }
      }
    }
    selectedCountry.value = match ?? countries.first;
  }

  void _applyFallback() {
    // Offline fallback: UAE default so prices keep rendering as before.
    selectedCountry.value = const Country(
      id: '',
      code: 'AE',
      name: 'UAE',
      nameAr: '',
      currencyCode: 'AED',
      currencySymbol: 'AED',
      currencySymbolAr: '',
      flagSvg: '',
      isDefault: true,
      effectiveRate: 1.0,
      sortOrder: 0,
    );
  }

  /// Fetches the public country list. Skips when the last fetch was < 5 min
  /// ago unless [force] is true. On failure the old list/selection is kept.
  Future<void> fetchCountries({bool force = false}) async {
    if (!force &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < _cacheTtl &&
        countries.isNotEmpty) {
      return;
    }
    isLoading.value = true;
    try {
      final response = await http.get(Uri.parse(Configss.getPublicCountries));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> list = decoded is List ? decoded : <dynamic>[];
        final parsed = list
            .whereType<Map>()
            .map((e) => Country.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        if (parsed.isNotEmpty) {
          countries.assignAll(parsed);
          _lastFetch = DateTime.now();
          _applySelection(selectedCountry.value?.code ?? 'AE');
        }
      }
    } catch (_) {
      // Keep old list/selection on failure.
    } finally {
      isLoading.value = false;
    }
  }

  /// Switches the active country, persists it, and refreshes payment charges.
  Future<void> selectCountry(Country c) async {
    selectedCountry.value = c;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, c.code);
    } catch (_) {}
    if (Get.isRegistered<PaymentChargesController>()) {
      Get.find<PaymentChargesController>().refreshForCountry(c.code);
    }
  }
}
