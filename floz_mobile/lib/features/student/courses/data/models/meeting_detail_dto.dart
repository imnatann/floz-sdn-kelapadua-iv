import '../../domain/entities/material_item.dart';
import '../../domain/entities/meeting_detail.dart';

class MeetingDetailDto {
  static MeetingDetail fromJson(Map<String, dynamic> json) {
    final m = json['meeting'] as Map<String, dynamic>? ?? const {};
    final mats = (json['materials'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((j) => MaterialItem(
              id: (j['id'] as num?)?.toInt() ?? 0,
              title: j['title']?.toString() ?? '-',
              type: materialTypeFromString(j['type']?.toString()),
              content: j['content']?.toString(),
              fileName: j['file_name']?.toString(),
              fileSize: (j['file_size'] as num?)?.toInt(),
              fileUrl: j['file_url']?.toString(),
              url: j['url']?.toString(),
              sortOrder: (j['sort_order'] as num?)?.toInt() ?? 0,
            ))
        .toList(growable: false);

    return MeetingDetail(
      meeting: MeetingHeader(
        id: (m['id'] as num?)?.toInt() ?? 0,
        meetingNumber: (m['meeting_number'] as num?)?.toInt() ?? 0,
        title: m['title']?.toString() ?? '-',
        description: m['description']?.toString(),
        isLocked: m['is_locked'] as bool? ?? true,
        subjectName: m['subject_name']?.toString() ?? '-',
        className: m['class_name']?.toString() ?? '-',
      ),
      materials: mats,
    );
  }
}
