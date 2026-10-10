/// Models for the GrabAtoZ push-notification inbox API.
///
/// Mirrors the backend spec (`In-App_Notifications___Mobile_API.docx`):
/// **no field in a notification object is ever null** — absent values arrive
/// as empty strings. Everything below is therefore non-nullable; check for "".
library;

/// Deep-link action attached to a notification.
class NotificationAction {
  /// home | product | category | offer | orders | cart | url | none
  final String screen;
  final String targetId;
  final String url;

  const NotificationAction({
    this.screen = 'none',
    this.targetId = '',
    this.url = '',
  });

  factory NotificationAction.fromJson(Map<String, dynamic> json) {
    String s(dynamic v) => v?.toString() ?? '';
    final screen = s(json['screen']);
    return NotificationAction(
      screen: screen.isEmpty ? 'none' : screen,
      targetId: s(json['targetId']),
      url: s(json['url']),
    );
  }
}

/// One row of the inbox list.
class NotificationItem {
  final String id;
  final String title;
  final String body;

  /// Empty string when there is no image — never null.
  final String imageUrl;
  final NotificationAction action;

  /// UTC send time. Used as the sort key and for local unread tracking.
  final DateTime sentAt;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl = '',
    this.action = const NotificationAction(),
    required this.sentAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    String s(dynamic v) => v?.toString() ?? '';
    DateTime sentAt;
    try {
      sentAt = DateTime.tryParse(s(json['sentAt']))?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    } catch (_) {
      sentAt = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }
    final actionJson = json['action'];
    return NotificationItem(
      id: s(json['id']),
      title: s(json['title']),
      body: s(json['body']),
      imageUrl: s(json['imageUrl']),
      action: actionJson is Map<String, dynamic>
          ? NotificationAction.fromJson(actionJson)
          : actionJson is Map
              ? NotificationAction.fromJson(
                  Map<String, dynamic>.from(actionJson))
              : const NotificationAction(),
      sentAt: sentAt,
    );
  }
}

/// Paged inbox response.
class NotificationInboxPage {
  final List<NotificationItem> items;
  final int page;
  final int limit;
  final int total;

  /// page * limit < total — drives infinite scroll.
  final bool hasMore;

  const NotificationInboxPage({
    this.items = const [],
    this.page = 1,
    this.limit = 20,
    this.total = 0,
    this.hasMore = false,
  });

  factory NotificationInboxPage.fromJson(Map<String, dynamic> json) {
    final raw = json['notifications'];
    final items = <NotificationItem>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map<String, dynamic>) {
          items.add(NotificationItem.fromJson(e));
        } else if (e is Map) {
          items.add(NotificationItem.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    int n(dynamic v) =>
        v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;
    final page = n(json['page']);
    final limit = n(json['limit']);
    final total = n(json['total']);
    final hasMoreJson = json['hasMore'];
    return NotificationInboxPage(
      items: items,
      page: page <= 0 ? 1 : page,
      limit: limit <= 0 ? 20 : limit,
      total: total,
      hasMore: hasMoreJson is bool
          ? hasMoreJson
          : (page <= 0 ? 1 : page) * (limit <= 0 ? 20 : limit) < total,
    );
  }
}
