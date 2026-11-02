/// HTTP client for the GrabAtoZ theme backend endpoint.
///
/// Base: https://api.grabatoz.ae
/// - GET /api/theme    public theme configuration (no auth)
///
/// Mirrors `LoyaltyApi`'s Dio setup, but attaches no auth headers:
/// the theme is public and is fetched before / without sign-in.
library;

import 'package:dio/dio.dart';

import 'package:graba2z/Configs/config.dart';
import 'package:graba2z/Models/app_theme.dart';

class ThemeApi {
  ThemeApi._();

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: Configss.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  /// Raw theme JSON.
  ///
  /// Never throws: any error / non-200 returns null so callers can
  /// fall back to the cached theme or the shipped defaults.
  static Future<Map<String, dynamic>?> fetchThemeJson() async {
    try {
      final res = await _dio.get(Configss.theme);
      if (res.statusCode == 200 && res.data is Map) {
        return Map<String, dynamic>.from(res.data as Map);
      }
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('ThemeApi.fetchThemeJson failed: $e');
      return null;
    }
  }

  /// Parsed theme, built on [fetchThemeJson]. Null on any failure.
  static Future<AppTheme?> fetchTheme() async {
    final json = await fetchThemeJson();
    if (json == null) return null;
    return AppTheme.fromJson(json);
  }
}
