import '../../domain/entities/student_grades.dart';

class GradeDto {
  static List<SubjectGradeSummary> listFromJson(List<dynamic> json) {
    return json
        .whereType<Map<String, dynamic>>()
        .map((j) => SubjectGradeSummary(
              subjectId: (j['subject_id'] as num?)?.toInt() ?? 0,
              subjectName: j['subject_name'] as String? ?? '-',
              average: (j['average'] as num?)?.toDouble() ?? 0,
              gradeCount: (j['grade_count'] as num?)?.toInt() ?? 0,
              kkm: (j['kkm'] as num?)?.toDouble() ?? 75,
            ))
        .toList(growable: false);
  }

  static SubjectGradeInfo detailFromJson(Map<String, dynamic> json) {
    final subjectJson = json['subject'] as Map<String, dynamic>? ?? {};
    final gradesList = (json['grades'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(_gradeDetailFromJson)
        .toList(growable: false);

    return SubjectGradeInfo(
      subjectId: (subjectJson['id'] as num?)?.toInt() ?? 0,
      subjectName: subjectJson['name'] as String? ?? '-',
      kkm: (subjectJson['kkm'] as num?)?.toDouble() ?? 75,
      grades: gradesList,
    );
  }

  static GradeDetail _gradeDetailFromJson(Map<String, dynamic> j) {
    return GradeDetail(
      id: (j['id'] as num?)?.toInt() ?? 0,
      dailyTestAvg: (j['daily_test_avg'] as num?)?.toDouble() ?? 0,
      midTest: (j['mid_test'] as num?)?.toDouble() ?? 0,
      finalTest: (j['final_test'] as num?)?.toDouble() ?? 0,
      knowledgeScore: (j['knowledge_score'] as num?)?.toDouble(),
      skillScore: (j['skill_score'] as num?)?.toDouble(),
      finalScore: (j['final_score'] as num?)?.toDouble() ?? 0,
      predicate: j['predicate'] as String? ?? '-',
      semester: j['semester'] as String? ?? '-',
      notes: j['notes'] as String?,
      createdAt: DateTime.tryParse(j['created_at']?.toString() ?? ''),
    );
  }
}
