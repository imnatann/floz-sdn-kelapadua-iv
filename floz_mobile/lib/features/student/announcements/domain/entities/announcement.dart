class AnnouncementSummary {
  final int id;
  final String title;
  final String excerpt;
  final String type;
  final bool isPinned;
  final String? coverImageUrl;
  final DateTime? createdAt;

  const AnnouncementSummary({
    required this.id,
    required this.title,
    required this.excerpt,
    required this.type,
    required this.isPinned,
    this.coverImageUrl,
    this.createdAt,
  });
}

class AnnouncementDetail {
  final int id;
  final String title;
  final String content;
  final String type;
  final bool isPinned;
  final String? coverImageUrl;
  final DateTime? createdAt;

  const AnnouncementDetail({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.isPinned,
    this.coverImageUrl,
    this.createdAt,
  });
}
