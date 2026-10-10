import 'package:awesome_notifications/awesome_notifications.dart';

import 'package:graba2z/Services/push_deep_link.dart';

class NotificationController {
  /// Use this method to detect when a new notification or a schedule is created
  @pragma("vm:entry-point")
  static Future<void> onNotificationCreatedMethod(
      ReceivedNotification receivedNotification) async {
    // Your code goes here
  }

  /// Use this method to detect every time that a new notification is displayed
  @pragma("vm:entry-point")
  static Future<void> onNotificationDisplayedMethod(
      ReceivedNotification receivedNotification) async {
    // Your code goes here
  }

  /// Use this method to detect if the user dismissed a notification
  @pragma("vm:entry-point")
  static Future<void> onDismissActionReceivedMethod(
      ReceivedAction receivedAction) async {
    // Your code goes here
  }

  /// Use this method to detect when the user taps on a notification or action button
  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    // Route FCM pushes (shown via awesome_notifications) to the right screen.
    final payload = receivedAction.payload ?? {};
    await PushDeepLink.handleRaw(
      screen: payload['screen']?.toString() ?? '',
      targetId: payload['targetId']?.toString() ?? '',
      url: payload['url']?.toString() ?? '',
    );
  }
}
