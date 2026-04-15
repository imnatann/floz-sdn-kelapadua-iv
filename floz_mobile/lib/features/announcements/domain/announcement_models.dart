class AnnouncementItem {
  final int id;
  final String title;
  final String content;
  final String type;
  final DateTime createdAt;
  final String? attachmentUrl;

  AnnouncementItem({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.createdAt,
    this.attachmentUrl,
  });

  factory AnnouncementItem.fromJson(Map<String, dynamic> json) {
    return AnnouncementItem(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      type: json['type'] ?? 'info',
      createdAt: DateTime.parse(json['created_at']),
      attachmentUrl: json['attachment_url'],
    );
  }
}
