/// In-app notification inbox screen.
///
/// Paged list from GET /api/notifications/inbox (newest first), driven by
/// the backend `hasMore` flag. Pull-to-refresh + infinite scroll. Unread
/// rows show a dot; tapping a row deep-links via [PushDeepLink].
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:graba2z/Controllers/notification_inbox_controller.dart';
import 'package:graba2z/Models/notification_models.dart';
import 'package:graba2z/Utils/appcolors.dart';
import 'package:graba2z/Widgets/customappbar.dart';

class NotificationInboxScreen extends StatefulWidget {
  const NotificationInboxScreen({super.key});

  @override
  State<NotificationInboxScreen> createState() =>
      _NotificationInboxScreenState();
}

class _NotificationInboxScreenState extends State<NotificationInboxScreen> {
  late final NotificationInboxController _c;
  bool _didMarkSeen = false;

  @override
  void initState() {
    super.initState();
    _c = Get.put(NotificationInboxController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(titleText: 'Notifications'),
      body: Obx(() {
        if (_c.isLoading.value && _c.items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_c.error.value != null && _c.items.isEmpty) {
          return _ErrorState(
            message: _c.error.value!,
            onRetry: _c.loadFirst,
          );
        }
        if (_c.items.isEmpty) {
          return const _EmptyState();
        }
        if (!_didMarkSeen && !_c.isLoading.value) {
          _didMarkSeen = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _c.markAllSeen();
          });
        }
        return RefreshIndicator(
          onRefresh: _c.refreshInbox,
          color: kPrimaryColor,
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.metrics.pixels >=
                      n.metrics.maxScrollExtent - 300 &&
                  !_c.isLoadingMore.value &&
                  _c.hasMore.value) {
                _c.loadMore();
              }
              return false;
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount:
                  _c.items.length + (_c.hasMore.value ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                if (index >= _c.items.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child:
                        Center(child: CircularProgressIndicator()),
                  );
                }
                final item = _c.items[index];
                return _InboxTile(
                  item: item,
                  unread: _c.isUnread(item),
                  onTap: () => _c.openItem(item),
                );
              },
            ),
          ),
        );
      }),
    );
  }
}

class _InboxTile extends StatelessWidget {
  final NotificationItem item;
  final bool unread;
  final VoidCallback onTap;

  const _InboxTile({
    required this.item,
    required this.unread,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: unread
              ? kPrimaryColor.withOpacity(0.08)
              : kdefwhiteColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Thumb(imageUrl: item.imageUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: unread
                                ? FontWeight.bold
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (unread)
                        Container(
                          width: 10,
                          height: 10,
                          margin:
                              const EdgeInsets.only(left: 8),
                          decoration: const BoxDecoration(
                            color: kPrimaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: kmediumblackColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _timeAgo(item.sentAt),
                    style: const TextStyle(
                      fontSize: 11,
                      color: klightblackColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final String imageUrl;
  const _Thumb({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 56,
        height: 56,
        child: imageUrl.isEmpty
            ? Container(
                color: kdefgreyColor,
                child: const Icon(
                  Icons.notifications_outlined,
                  color: kPrimaryColor,
                ),
              )
            : CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: kdefgreyColor,
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2),
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: kdefgreyColor,
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: kPrimaryColor,
                  ),
                ),
              ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_off_outlined,
              size: 64, color: klightblackColor),
          SizedBox(height: 12),
          Text(
            'No notifications yet',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 4),
          Text(
            'Offers and order updates will appear here.',
            style: TextStyle(fontSize: 12, color: kmediumblackColor),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined,
              size: 64, color: klightblackColor),
          const SizedBox(height: 12),
          Text(message,
              style:
                  const TextStyle(fontSize: 13, color: kmediumblackColor)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: kdefwhiteColor),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().toUtc().difference(dt.toUtc());
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}
