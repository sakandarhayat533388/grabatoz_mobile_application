/// HTTP client for the GrabAtoZ referrals backend endpoints.
///
/// Base: https://api.grabatoz.ae
/// - GET  /api/referrals/settings          public referral settings + offer
/// - GET  /api/referrals/me?country=&lang=  user's referral panel (auth)
/// - GET  /api/referrals/validate/<code>    check a referral code (public)
/// - POST /api/referrals/quote              preview referral reward (auth)
///
/// Mirrors `NotificationApi`: bearer token is attached from the
/// SharedPreferences key 'token' when one exists.
library;

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:graba2z/Configs/config.dart';
import 'package:graba2z/Models/referral_models.dart';

class ReferralApi {
  ReferralApi._();

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: Configss.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    if (token.isNotEmpty) {
      return {'Authorization': 'Bearer $token'};
    }
    return const {};
  }

  /// Public referral settings.
  ///
  /// Response shape: `{settings: {...}}`, with the current offer carried
  /// inside that same top-level payload. [ReferralSettings.fromPayload]
  /// handles the extraction, so the whole response map is passed through.
  ///
  /// Never throws: any failure returns null and the referral UI stays hidden.
  static Future<ReferralSettings?> fetchSettings() async {
    try {
      final res = await _dio.get(
        Configss.referralSettings,
        options: Options(headers: await _headers()),
      );
      if (res.statusCode == 200 && res.data is Map) {
        return ReferralSettings.fromPayload(
            Map<String, dynamic>.from(res.data as Map));
      }
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('ReferralApi.fetchSettings failed: $e');
      return null;
    }
  }

  /// The signed-in user's referral panel (own code, share text, stats and
  /// referred friends) for [country] / [lang].
  ///
  /// Throws on failure so the UI can show a retry state.
  static Future<ReferralPanel> fetchMe({
    required String country,
    required String lang,
  }) async {
    final query = {
      'country': country,
      'lang': lang,
    };
    final res = await _dio.get(
      Configss.referralMe,
      queryParameters: query,
      options: Options(headers: await _headers()),
    );
    if (res.statusCode == 200 && res.data is Map) {
      return ReferralPanel.fromJson(
          Map<String, dynamic>.from(res.data as Map));
    }
    throw Exception('Referral panel request failed: ${res.statusCode}');
  }

  /// Check whether [code] is a usable referral code. Public — no auth header.
  ///
  /// The server answers HTTP 200 with `{valid: false, reason: ...}` for a
  /// bad code, so a 200 response is always parsed, never treated as an
  /// error. Never throws: a transport failure is reported the same way as
  /// an unknown code.
  static Future<ReferralValidation> validate(String code) async {
    try {
      final res = await _dio.get(
        Configss.referralValidate(Uri.encodeComponent(code)),
      );
      if (res.statusCode == 200 && res.data is Map) {
        return ReferralValidation.fromJson(
            Map<String, dynamic>.from(res.data as Map));
      }
      return ReferralValidation.fromJson(
          const {'valid': false, 'reason': 'unknown_code'});
    } catch (e) {
      // ignore: avoid_print
      print('ReferralApi.validate failed: $e');
      return ReferralValidation.fromJson(
          const {'valid': false, 'reason': 'unknown_code'});
    }
  }

  /// Preview the referral reward available against an order whose eligible
  /// amount is [eligibleAmount].
  ///
  /// Throws on failure so checkout can surface the error.
  static Future<ReferralQuote> quote({
    required double eligibleAmount,
  }) async {
    final res = await _dio.post(
      Configss.referralQuote,
      data: {
        'eligibleAmount': eligibleAmount,
      },
      options: Options(headers: await _headers()),
    );
    if (res.statusCode == 200 && res.data is Map) {
      return ReferralQuote.fromJson(
          Map<String, dynamic>.from(res.data as Map));
    }
    throw Exception('Referral quote request failed: ${res.statusCode}');
  }
}
