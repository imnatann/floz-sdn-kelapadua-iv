import '../../domain/entities/notifications_page.dart';
import 'notification_dto.dart';

class NotificationsPageDto {
  static NotificationsPage fromJson(Map<String, dynamic> json) {
    final items = (json['data'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(NotificationDto.fromJson)
        .toList(growable: false);
    final meta = json['meta'] as Map<String, dynamic>? ?? const {};
    return NotificationsPage(
      items: items,
      currentPage: (meta['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (meta['last_page'] as num?)?.toInt() ?? 1,
      total: (meta['total'] as num?)?.toInt() ?? items.length,
      unreadCount: (meta['unread_count'] as num?)?.toInt() ?? 0,
    );
  }
}
