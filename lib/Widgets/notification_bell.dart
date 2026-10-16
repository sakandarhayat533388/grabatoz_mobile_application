/// Notification bell button with an unread badge.
///
/// Drop it into any AppBar `actions`:
/// ```dart
/// appBar: CustomAppBar(
///   titleText: 'Home',
///   actionicon: const NotificationBellButton(),
///   tapaction: () => Get.to(() => const NotificationInboxScreen()),
/// )
/// ```
/// Tapping opens the inbox screen.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:graba2z/Controllers/notification_inbox_controller.dart';
import 'package:graba2z/Views/Home/Screens/Settings/Modules/Notification Inbox/notification_inbox_screen.dart';
import 'package:graba2z/Utils/appcolors.dart';

class NotificationBellButton extends StatelessWidget {
  final Color iconColor;
  final double iconSize;

  const NotificationBellButton({
    super.key,
    this.iconColor = kdefwhiteColor,
    this.iconSize = 26,
  });

  @override
  Widget build(BuildContext context) {
    final c = Get.put(NotificationInboxController());
    return Obx(
      () => Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            icon: Icon(Icons.notifications_outlined,
                color: iconColor, size: iconSize),
            onPressed: () =>
                Get.to(() => const NotificationInboxScreen()),
          ),
          if (c.unreadCount.value > 0)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: kredColor,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Text(
                  c.unreadCount.value > 99
                      ? '99+'
                      : c.unreadCount.value.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: kdefwhiteColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
