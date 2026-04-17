import '../../domain/entities/meeting_summary.dart';

class MeetingsDto {
  static CourseMeetings fromJson(Map<String, dynamic> json) {
    final ta = json['teaching_assignment'] as Map<String, dynamic>? ?? const {};
    final list = (json['meetings'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((j) => MeetingSummary(
              id: (j['id'] as num?)?.toInt() ?? 0,
              meetingNumber: (j['meeting_number'] as num?)?.toInt() ?? 0,
              title: j['title']?.toString() ?? '-',
              description: j['description']?.toString(),
              isLocked: j['is_locked'] as bool? ?? true,
              materialCount: (j['material_count'] as num?)?.toInt() ?? 0,
            ))
        .toList(growable: false);

    return CourseMeetings(
      course: CourseInfo(
        id: (ta['id'] as num?)?.toInt() ?? 0,
        subjectName: ta['subject_name']?.toString() ?? '-',
        teacherName: ta['teacher_name']?.toString() ?? '-',
        className: ta['class_name']?.toString() ?? '-',
      ),
      meetings: list,
    );
  }
}
