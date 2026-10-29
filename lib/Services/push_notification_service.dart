/// App-side FCM push notification service for GrabAtoZ.
///
/// Implements the backend spec (`In-App_Notifications___Mobile_API.docx`):
/// - requests permission + fetches the FCM token
/// - POST /api/notifications/devices on launch, after login and on refresh
/// - DELETE /api/notifications/devices/:token on logout
/// - foreground messages are rendered with awesome_notifications on the
///   channel matching the payload's sound id
/// - taps (foreground / background / terminated) route via [PushDeepLink]
///
/// IMPORTANT: [init] must only be called after `Firebase.initializeApp()`
/// has succeeded. Everything is guarded by [firebaseReady] so the app runs
/// fine without google-services.json / GoogleService-Info.plist.
library;

import 'dart:io';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:graba2z/Services/notification_api.dart';
import 'package:graba2z/Services/push_deep_link.dart';

/// Must be top-level for `FirebaseMessaging.onBackgroundMessage`.
@pragma('vm:entry-point')
Future<void> fcmBackgroundMessageHandler(RemoteMessage message) async {
  // Background/terminated: the OS already draws messages that carry a
  // notification block. Rendering again here would show it TWICE.
  // Only data-only messages need local rendering.
  if (message.notification == null) {
    await PushNotificationService.showMessage(message);
  }
}

class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  /// Set to true by main() only after Firebase.initializeApp() succeeds.
  static bool firebaseReady = false;

  static const String _tokenPrefKey = 'fcm_token';

  /// Spec sound ids -> awesome_notifications channel keys.
  /// The channels themselves are created in main.dart (AwesomeNotifications
  /// init) so the app theme colors stay in one place.
  static const Map<String, String> soundChannels = {
    'default': 'push_default',
    'chime': 'push_chime',
    'ding': 'push_ding',
    'cash': 'push_cash',
    'alert': 'push_alert',
    'silent': 'push_silent',
  };

  static String channelForSound(String? sound) {
    final key = (sound ?? 'default').trim().toLowerCase();
    return soundChannels[key] ?? soundChannels['default']!;
  }

  /// All channel keys created in main.dart. The backend now sends
  /// `android.notification.channel_id` in the FCM payload (and may mirror it
  /// in the data block); when the app renders a message itself (foreground,
  /// or data-only in background) it must honour that channel so the custom
  /// sound matches what the OS plays for background/terminated messages.
  static const Set<String> knownChannels = {
    'push_default',
    'push_chime',
    'push_ding',
    'push_cash',
    'push_alert',
    'push_silent',
  };

  /// Priority: explicit channel id from the payload (android notification
  /// block or data), then the payload's sound id, then the default channel.
  static String resolveChannelKey({String? channelId, String? sound}) {
    final cid = (channelId ?? '').trim();
    if (cid.isNotEmpty) {
      if (knownChannels.contains(cid)) return cid;
      // Backend might send the bare sound id (e.g. "chime") as channel id.
      final mapped = soundChannels[cid.toLowerCase()];
      if (mapped != null) return mapped;
    }
    return channelForSound(sound);
  }

  /// Call once from main() after Firebase.initializeApp() succeeded.
  Future<void> init() async {
    if (!firebaseReady) return;
    final messaging = FirebaseMessaging.instance;

    try {
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (_) {}

    if (Platform.isIOS) {
      try {
        await messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      } catch (_) {}
    }

    FirebaseMessaging.onBackgroundMessage(fcmBackgroundMessageHandler);

    // Foreground: the OS does NOT draw a banner — render it ourselves.
    FirebaseMessaging.onMessage.listen((message) async {
      await showMessage(message);
    });

    // Background tap.
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      PushDeepLink.handleData(message.data);
    });

    // Terminated-state tap (cold start).
    try {
      final initial = await messaging.getInitialMessage();
      if (initial != null) {
        // Small delay so the first frame / GetX is ready.
        Future.delayed(const Duration(seconds: 1), () {
          PushDeepLink.handleData(initial.data);
        });
      }
    } catch (_) {}

    // Token refresh.
    messaging.onTokenRefresh.listen((token) async {
      await _persistToken(token);
      await registerDevice(tokenOverride: token);
    });

    // Spec: (re-)register on every launch once the FCM token is available.
    final token = await _currentToken();
    if (token != null) {
      await _persistToken(token);
      await registerDevice(tokenOverride: token);
    }
  }

  Future<String?> _currentToken() async {
    try {
      // Bounded wait: on a fresh install the token is created over the
      // network and this call can stall for a long time. On timeout the
      // token still arrives later via onTokenRefresh and registers then.
      return await FirebaseMessaging.instance
          .getToken()
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      return null;
    }
  }

  Future<void> _persistToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenPrefKey, token);
    } catch (_) {}
  }

  static Future<String?> storedToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenPrefKey);
    } catch (_) {
      return null;
    }
  }

  /// POST /api/notifications/devices. Attaches the bearer token when the
  /// user is logged in (the backend then links the device to the account).
  /// No-op when Firebase is not configured. Never throws.
  Future<bool> registerDevice({String? tokenOverride}) async {
    if (!firebaseReady) return false;
    try {
      final token = tokenOverride ?? await _currentToken();
      if (token == null || token.length < 20) return false;

      String appVersion = '';
      try {
        appVersion = (await PackageInfo.fromPlatform()).version;
      } catch (_) {}
      String deviceName = '';
      try {
        deviceName = Platform.localHostname;
      } catch (_) {
        deviceName = Platform.operatingSystem;
      }

      return await NotificationApi.registerDevice(
        token: token,
        appVersion: appVersion,
        deviceName: deviceName,
      );
    } catch (_) {
      return false;
    }
  }

  /// DELETE /api/notifications/devices/:token. Call on logout and when the
  /// customer disables notifications. Never throws.
  Future<bool> deregisterDevice() async {
    try {
      final token = await storedToken();
      if (token == null || token.isEmpty) return true;
      final ok = await NotificationApi.deregisterDevice(token);
      if (ok) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_tokenPrefKey);
      }
      return ok;
    } catch (_) {
      return false;
    }
  }

  /// Render an FCM message as a local notification via awesome_notifications.
  /// Safe to call from the background isolate (no instance state used).
  static Future<void> showMessage(RemoteMessage message) async {
    try {
      final data = message.data;
      String s(dynamic v) => v?.toString() ?? '';

      final title = message.notification?.title?.isNotEmpty == true
          ? message.notification!.title!
          : (s(data['title']).isNotEmpty ? s(data['title']) : 'Graba2z');
      final body = message.notification?.body ?? s(data['body']);
      final imageUrl = message.notification?.android?.imageUrl?.isNotEmpty == true
          ? message.notification!.android!.imageUrl!
          : (message.notification?.apple?.imageUrl?.isNotEmpty == true
              ? message.notification!.apple!.imageUrl!
              : s(data['imageUrl']));

      final sound = s(data['sound']).isNotEmpty
          ? s(data['sound'])
          : s(message.notification?.android?.sound ??
              message.notification?.apple?.sound ??
              'default');
      // Backend sends android.notification.channel_id: prefer it so the
      // locally rendered notification uses the same channel (and custom
      // sound) the OS would use when the app is backgrounded/terminated.
      final payloadChannelId = s(message.notification?.android?.channelId)
              .isNotEmpty
          ? s(message.notification?.android?.channelId)
          : (s(data['channel_id']).isNotEmpty
              ? s(data['channel_id'])
              : s(data['channelId']));
      final channelKey =
          resolveChannelKey(channelId: payloadChannelId, sound: sound);
      final notificationId = s(data['notificationId']);
      final id = notificationId.isEmpty
          ? DateTime.now().millisecondsSinceEpoch.remainder(0x7fffffff)
          : notificationId.hashCode.abs();

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: channelKey,
          title: title,
          body: body.isEmpty ? null : body,
          bigPicture: imageUrl.isEmpty ? null : imageUrl,
          notificationLayout: imageUrl.isEmpty
              ? NotificationLayout.Default
              : NotificationLayout.BigPicture,
          payload: {
            'screen': s(data['screen']),
            'targetId': s(data['targetId']),
            'url': s(data['url']),
            'notificationId': notificationId,
          },
        ),
      );
    } catch (e) {
      // ignore: avoid_print
      print('PushNotificationService.showMessage failed: $e');
    }
  }
}
