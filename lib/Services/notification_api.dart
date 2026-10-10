/// HTTP client for the GrabAtoZ push-notification backend endpoints.
///
/// Spec: `In-App_Notifications___Mobile_API.docx`
/// Base: https://api.grabatoz.ae
/// - POST   /api/notifications/devices          register / refresh FCM token
/// - DELETE /api/notifications/devices/:token   deregister on logout
/// - GET    /api/notifications/inbox            paged inbox list
///
/// All three endpoints work with or without a logged-in user: the bearer
/// token is attached when one exists. They never return 401 — an invalid
/// token degrades to guest, so no 401 handling is needed here.
library;

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:graba2z/Configs/config.dart';
import 'package:graba2z/Models/notification_models.dart';

class NotificationApi {
  NotificationApi._();

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: Configss.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  /// The app is English-only today; flip to 'ar' when Arabic ships.
  static String currentLanguage() => 'en';

  /// Two-letter country code used for platform/country targeting.
  /// The store is UAE-first, matching the rest of the app.
  static String deviceCountry() => 'AE';

  static String currentPlatform() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }

  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    if (token.isNotEmpty) {
      return {'Authorization': 'Bearer $token'};
    }
    return const {};
  }

  /// Register (or refresh) this install's FCM token.
  /// Safe to call on every launch — the backend upserts on token.
  /// Never throws: registration is best-effort and must not break the app.
  static Future<bool> registerDevice({
    required String token,
    String? appVersion,
    String? deviceName,
  }) async {
    if (token.length < 20) return false;
    try {
      final res = await _dio.post(
        '/api/notifications/devices',
        data: {
          'token': token,
          'platform': currentPlatform(),
          'country': deviceCountry(),
          'language': currentLanguage(),
          if (appVersion != null && appVersion.isNotEmpty)
            'appVersion': appVersion,
          if (deviceName != null && deviceName.isNotEmpty)
            'deviceName': deviceName,
        },
        options: Options(headers: await _headers()),
      );
      return res.statusCode == 200;
    } catch (e) {
      // ignore: avoid_print
      print('NotificationApi.registerDevice failed: $e');
      return false;
    }
  }

  /// Stop pushes to this install. Safe to call blind — the backend returns
  /// 200 even when the token is unknown. Never throws.
  static Future<bool> deregisterDevice(String token) async {
    if (token.isEmpty) return true;
    try {
      final res = await _dio.delete(
        '/api/notifications/devices/$token',
        options: Options(headers: await _headers()),
      );
      return res.statusCode == 200;
    } catch (e) {
      // ignore: avoid_print
      print('NotificationApi.deregisterDevice failed: $e');
      return false;
    }
  }

  /// Paged inbox. `platform` and `country` are REQUIRED — without them the
  /// customer silently misses every platform/country-targeted campaign.
  /// Throws on failure so the UI can show a retry state.
  static Future<NotificationInboxPage> fetchInbox({
    int page = 1,
    int limit = 20,
  }) async {
    final query = {
      'page': page.clamp(1, 1 << 31).toString(),
      'limit': limit.clamp(1, 50).toString(),
      'platform': currentPlatform(),
      'country': deviceCountry(),
      'lang': currentLanguage(),
    };
    final res = await _dio.get(
      '/api/notifications/inbox',
      queryParameters: query,
      options: Options(headers: await _headers()),
    );
    if (res.statusCode == 200 && res.data is Map) {
      return NotificationInboxPage.fromJson(
          Map<String, dynamic>.from(res.data as Map));
    }
    throw Exception('Inbox request failed: ${res.statusCode}');
  }
}
