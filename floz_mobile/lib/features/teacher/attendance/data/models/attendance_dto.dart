import '../../domain/entities/attendance_roster.dart';

class AttendanceRosterDto {
  static AttendanceRoster fromJson(Map<String, dynamic> json) {
    final meetingJson = json['meeting'] as Map<String, dynamic>? ?? {};
    final classJson = json['class'] as Map<String, dynamic>? ?? {};
    final taJson = json['teaching_assignment'] as Map<String, dynamic>? ?? {};
    final subjectJson = taJson['subject'] as Map<String, dynamic>? ?? {};
    final studentsJson = json['students'] as List? ?? [];

    return AttendanceRoster(
      meeting: MeetingInfo(
        id: (meetingJson['id'] as num?)?.toInt() ?? 0,
        meetingNumber: (meetingJson['meeting_number'] as num?)?.toInt() ?? 0,
        title: meetingJson['title'] as String? ?? '-',
      ),
      classInfo: ClassInfo(
        id: (classJson['id'] as num?)?.toInt() ?? 0,
        name: classJson['name'] as String? ?? '-',
      ),
      subject: SubjectInfo(
        id: (subjectJson['id'] as num?)?.toInt() ?? 0,
        name: subjectJson['name'] as String? ?? '-',
      ),
      students: studentsJson
          .whereType<Map<String, dynamic>>()
          .map((s) => StudentAttendance(
                id: (s['id'] as num?)?.toInt() ?? 0,
                name: s['name'] as String? ?? '-',
                nis: s['nis']?.toString() ?? '-',
                status: s['status'] as String?,
                note: s['note'] as String?,
              ))
          .toList(growable: false),
    );
  }
}
