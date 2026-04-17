import '../../domain/entities/attendance_recap.dart';
import '../../domain/entities/grade_recap.dart';

class GradeRecapDto {
  static GradeRecap fromJson(Map<String, dynamic> json) {
    final taJson = json['teaching_assignment'] as Map<String, dynamic>? ?? {};
    final studentsJson = json['students'] as List? ?? [];

    return GradeRecap(
      taInfo: RecapTaInfo(
        id: (taJson['id'] as num?)?.toInt() ?? 0,
        subjectName: taJson['subject_name'] as String? ?? '-',
        className: taJson['class_name'] as String? ?? '-',
      ),
      students: studentsJson
          .whereType<Map<String, dynamic>>()
          .map((s) => StudentGradeRecap(
                id: (s['id'] as num?)?.toInt() ?? 0,
                name: s['name'] as String? ?? '-',
                nis: s['nis']?.toString() ?? '-',
                dailyTestAvg: (s['daily_test_avg'] as num?)?.toDouble(),
                midTest: (s['mid_test'] as num?)?.toDouble(),
                finalTest: (s['final_test'] as num?)?.toDouble(),
                finalScore: (s['final_score'] as num?)?.toDouble(),
                predicate: s['predicate'] as String?,
              ))
          .toList(growable: false),
    );
  }
}
