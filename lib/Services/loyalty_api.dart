/// HTTP client for the GrabAtoZ Grabian Points (loyalty) backend endpoints.
///
/// Base: https://api.grabatoz.ae
/// - GET  /api/loyalty/settings            public earn/redeem settings + rules
/// - GET  /api/loyalty/me?page=&limit=     points balance + paged history (auth)
/// - POST /api/loyalty/quote               preview a points redemption (auth)
/// - GET  /api/loyalty/announcements       unseen loyalty announcements (auth)
/// - POST /api/loyalty/announcements/ack   mark announcements as seen (auth)
///
/// Mirrors `NotificationApi`: bearer token is attached from the
/// SharedPreferences key 'token' when one exists.
library;

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:graba2z/Configs/config.dart';
import 'package:graba2z/Models/loyalty_models.dart';

class LoyaltyApi {
  LoyaltyApi._();

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

  /// Public loyalty settings.
  ///
  /// Response shape: `{settings: {...}, rules: [...]}` — only the
  /// `settings` object is parsed here; the rules are part of that payload's
  /// sibling field and are not needed by [LoyaltySettings].
  ///
  /// Never throws: settings are best-effort (the UI can fall back to
  /// defaults / hide the points UI), so any failure returns null.
  static Future<LoyaltySettings?> fetchSettings() async {
    try {
      final res = await _dio.get(
        Configss.loyaltySettings,
        options: Options(headers: await _headers()),
      );
      if (res.statusCode == 200 && res.data is Map) {
        final data = Map<String, dynamic>.from(res.data as Map);
        final settings = data['settings'];
        if (settings is Map) {
          return LoyaltySettings.fromJson(
              Map<String, dynamic>.from(settings));
        }
      }
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('LoyaltyApi.fetchSettings failed: $e');
      return null;
    }
  }

  /// The signed-in user's points account: balance plus a paged history.
  ///
  /// Throws on failure so the UI can show a retry state.
  static Future<LoyaltyAccount> fetchMe({
    int page = 1,
    int limit = 20,
  }) async {
    final query = {
      'page': page.clamp(1, 1 << 31).toString(),
      'limit': limit.clamp(1, 50).toString(),
    };
    final res = await _dio.get(
      Configss.loyaltyMe,
      queryParameters: query,
      options: Options(headers: await _headers()),
    );
    if (res.statusCode == 200 && res.data is Map) {
      return LoyaltyAccount.fromJson(
          Map<String, dynamic>.from(res.data as Map));
    }
    throw Exception('Loyalty account request failed: ${res.statusCode}');
  }

  /// Preview redeeming [requestedPoints] against an order whose eligible
  /// amount is [eligibleAmount]: how much discount those points buy and
  /// whether the redemption is allowed.
  ///
  /// Throws on failure so checkout can surface the error.
  static Future<LoyaltyQuote> quote({
    required double eligibleAmount,
    required int requestedPoints,
  }) async {
    final res = await _dio.post(
      Configss.loyaltyQuote,
      data: {
        'eligibleAmount': eligibleAmount,
        'requestedPoints': requestedPoints,
      },
      options: Options(headers: await _headers()),
    );
    if (res.statusCode == 200 && res.data is Map) {
      return LoyaltyQuote.fromJson(
          Map<String, dynamic>.from(res.data as Map));
    }
    throw Exception('Loyalty quote request failed: ${res.statusCode}');
  }

  /// Loyalty announcements the user has not acknowledged yet.
  ///
  /// Never throws: announcements are decorative, so any failure returns an
  /// empty result (`hasAny == false`) and nothing is shown.
  static Future<LoyaltyAnnouncements> fetchAnnouncements() async {
    try {
      final res = await _dio.get(
        Configss.loyaltyAnnouncements,
        options: Options(headers: await _headers()),
      );
      if (res.statusCode == 200 && res.data is Map) {
        return LoyaltyAnnouncements.fromJson(
            Map<String, dynamic>.from(res.data as Map));
      }
      return LoyaltyAnnouncements.fromJson(const {});
    } catch (e) {
      // ignore: avoid_print
      print('LoyaltyApi.fetchAnnouncements failed: $e');
      return LoyaltyAnnouncements.fromJson(const {});
    }
  }

  /// Mark the current announcements as seen so they are not shown again.
  /// Never throws.
  static Future<bool> ackAnnouncements() async {
    try {
      final res = await _dio.post(
        Configss.loyaltyAnnouncementsAck,
        data: const <String, dynamic>{},
        options: Options(headers: await _headers()),
      );
      return res.statusCode == 200;
    } catch (e) {
      // ignore: avoid_print
      print('LoyaltyApi.ackAnnouncements failed: $e');
      return false;
    }
  }
}
