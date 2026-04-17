import '../../domain/entities/course.dart';

class CourseDto {
  static List<Course> listFromJson(List<dynamic> raw) {
    return raw
        .whereType<Map<String, dynamic>>()
        .map((j) => Course(
              id: (j['id'] as num?)?.toInt() ?? 0,
              subjectName: j['subject_name']?.toString() ?? '-',
              teacherName: j['teacher_name']?.toString() ?? '-',
              meetingCount: (j['meeting_count'] as num?)?.toInt() ?? 0,
              materialCount: (j['material_count'] as num?)?.toInt() ?? 0,
            ))
        .toList(growable: false);
  }
}
