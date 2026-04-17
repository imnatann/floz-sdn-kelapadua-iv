import '../../domain/entities/notification_item.dart';

class NotificationDto {
  static NotificationItem fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'other',
      title: json['title']?.toString() ?? 'Notifikasi',
      body: json['body']?.toString() ?? '',
      icon: json['icon']?.toString() ?? 'bell',
      action: _actionFromJson(json['action']),
      readAt: _parseDate(json['read_at']),
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
    );
  }

  static NotificationAction? _actionFromJson(dynamic raw) {
    if (raw is! Map<String, dynamic>) return null;
    final screen = raw['screen']?.toString();
    if (screen == null || screen.isEmpty) return null;
    final args = (raw['args'] is Map)
        ? Map<String, dynamic>.from(raw['args'] as Map)
        : <String, dynamic>{};
    return NotificationAction(screen: screen, args: args);
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }
}
