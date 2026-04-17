class NotificationAction {
  final String screen;
  final Map<String, dynamic> args;
  const NotificationAction({required this.screen, this.args = const {}});
}

class NotificationItem {
  final String id;
  final String type;
  final String title;
  final String body;
  final String icon;
  final NotificationAction? action;
  final DateTime? readAt;
  final DateTime createdAt;

  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.icon,
    this.action,
    this.readAt,
    required this.createdAt,
  });

  bool get isRead => readAt != null;
}
