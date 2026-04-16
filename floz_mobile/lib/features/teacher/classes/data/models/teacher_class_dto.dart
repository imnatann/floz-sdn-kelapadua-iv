import '../../domain/entities/class_meetings.dart';
import '../../domain/entities/teaching_assignment_summary.dart';

class TeacherClassDto {
  static List<TeachingAssignmentSummary> listFromJson(List<dynamic> json) {
    return json
        .whereType<Map<String, dynamic>>()
        .map((j) => TeachingAssignmentSummary(
              id: (j['id'] as num?)?.toInt() ?? 0,
              subjectName: j['subject_name'] as String? ?? '',
              className: j['class_name'] as String? ?? '',
              academicYear: j['academic_year'] as String? ?? '',
              studentCount: (j['student_count'] as num?)?.toInt() ?? 0,
              meetingCount: (j['meeting_count'] as num?)?.toInt() ?? 0,
            ))
        .toList(growable: false);
  }

  static ClassMeetings meetingsFromJson(Map<String, dynamic> json) {
    final ta = json['teaching_assignment'] as Map<String, dynamic>? ?? {};
    final rawMeetings = json['meetings'] as List? ?? const [];
    final meetings = rawMeetings
        .whereType<Map<String, dynamic>>()
        .map((m) => MeetingSummary(
              id: (m['id'] as num?)?.toInt() ?? 0,
              meetingNumber: (m['meeting_number'] as num?)?.toInt() ?? 0,
              title: m['title'] as String? ?? '',
              description: m['description'] as String?,
              isLocked: m['is_locked'] as bool? ?? false,
              materialCount: (m['material_count'] as num?)?.toInt() ?? 0,
              assignmentCount: (m['assignment_count'] as num?)?.toInt() ?? 0,
            ))
        .toList(growable: false);

    return ClassMeetings(
      taId: (ta['id'] as num?)?.toInt() ?? 0,
      subjectName: ta['subject_name'] as String? ?? '',
      className: ta['class_name'] as String? ?? '',
      meetings: meetings,
    );
  }
}
