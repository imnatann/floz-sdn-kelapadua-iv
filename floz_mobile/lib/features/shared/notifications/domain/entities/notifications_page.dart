import 'notification_item.dart';

class NotificationsPage {
  final List<NotificationItem> items;
  final int currentPage;
  final int lastPage;
  final int total;
  final int unreadCount;

  const NotificationsPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.unreadCount,
  });
}
