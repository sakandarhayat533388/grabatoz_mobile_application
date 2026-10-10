/// GetX controller for the notification inbox screen.
///
/// - Paged loading driven by the backend's `hasMore` flag.
/// - Local unread tracking: the server stores no read state, so the newest
///   `sentAt` the customer has seen is persisted in SharedPreferences
///   (`notif_newest_seen_sentat`) and anything newer counts as unread.
/// - Tapping an item routes through [PushDeepLink].
library;

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:graba2z/Models/notification_models.dart';
import 'package:graba2z/Services/notification_api.dart';
import 'package:graba2z/Services/push_deep_link.dart';

class NotificationInboxController extends GetxController {
  static const int _limit = 20;
  static const String _seenKey = 'notif_newest_seen_sentat';

  final items = <NotificationItem>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  final error = RxnString();
  final unreadCount = 0.obs;

  int _page = 1;
  DateTime? _seenAt;
  bool _firstLoad = true;

  @override
  void onInit() {
    super.onInit();
    loadFirst();
  }

  Future<void> loadFirst() async {
    isLoading.value = true;
    error.value = null;
    _page = 1;
    try {
      await _loadSeen();
      final page = await NotificationApi.fetchInbox(page: 1, limit: _limit);
      items.assignAll(page.items);
      hasMore.value = page.hasMore;
      _page = page.page;
      if (_firstLoad) {
        // Never badge-shock on a fresh install: treat everything already
        // in the inbox as seen; only newer arrivals count as unread.
        _firstLoad = false;
        await markAllSeen(silent: true);
      }
      _recountUnread();
    } catch (e) {
      error.value = 'Could not load notifications. Pull to retry.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || isLoading.value || !hasMore.value) return;
    isLoadingMore.value = true;
    try {
      final page =
          await NotificationApi.fetchInbox(page: _page + 1, limit: _limit);
      items.addAll(page.items);
      hasMore.value = page.hasMore;
      _page = page.page;
      _recountUnread();
    } catch (_) {
      // Keep the list the user already has; a retry happens on next scroll.
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> refreshInbox() => loadFirst();

  bool isUnread(NotificationItem item) {
    final seen = _seenAt;
    if (seen == null) return true;
    return item.sentAt.isAfter(seen);
  }

  /// Mark everything currently loaded as seen.
  Future<void> markAllSeen({bool silent = false}) async {
    if (items.isEmpty) {
      if (!silent) _recountUnread();
      return;
    }
    final newest = items
        .map((e) => e.sentAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    _seenAt = newest;
    unreadCount.value = 0;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_seenKey, newest.toIso8601String());
    } catch (_) {}
    if (!silent) update();
  }

  /// Open a notification: mark it seen, then deep-link.
  Future<void> openItem(NotificationItem item) async {
    final epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    final current = _seenAt ?? epoch;
    if (item.sentAt.isAfter(current)) {
      _seenAt = item.sentAt;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_seenKey, item.sentAt.toIso8601String());
      } catch (_) {}
      _recountUnread();
    }
    await PushDeepLink.handle(item.action);
  }

  Future<void> _loadSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_seenKey);
      _seenAt = raw == null ? null : DateTime.tryParse(raw)?.toUtc();
    } catch (_) {
      _seenAt = null;
    }
  }

  void _recountUnread() {
    final seen = _seenAt;
    if (seen == null) {
      unreadCount.value = items.length;
    } else {
      unreadCount.value =
          items.where((i) => i.sentAt.isAfter(seen)).length;
    }
  }
}
