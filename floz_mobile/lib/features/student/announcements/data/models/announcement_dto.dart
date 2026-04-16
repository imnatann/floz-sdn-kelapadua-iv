import '../../domain/entities/announcement.dart';

class AnnouncementDto {
  static List<AnnouncementSummary> listFromJson(List<dynamic> json) {
    return json
        .whereType<Map<String, dynamic>>()
        .map((j) => AnnouncementSummary(
              id: (j['id'] as num?)?.toInt() ?? 0,
              title: j['title'] as String? ?? '',
              excerpt: j['excerpt'] as String? ?? '',
              type: j['type'] as String? ?? '',
              isPinned: j['is_pinned'] as bool? ?? false,
              coverImageUrl: j['cover_image_url'] as String?,
              createdAt: DateTime.tryParse(j['created_at']?.toString() ?? ''),
            ))
        .toList(growable: false);
  }

  static AnnouncementDetail detailFromJson(Map<String, dynamic> json) {
    return AnnouncementDetail(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      type: json['type'] as String? ?? '',
      isPinned: json['is_pinned'] as bool? ?? false,
      coverImageUrl: json['cover_image_url'] as String?,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}
