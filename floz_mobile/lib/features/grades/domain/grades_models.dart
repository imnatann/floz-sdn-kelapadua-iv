class SubjectGradeSummary {
  final int subjectId;
  final String subjectName;
  final double average;
  final int gradeCount;

  SubjectGradeSummary({
    required this.subjectId,
    required this.subjectName,
    required this.average,
    required this.gradeCount,
  });

  factory SubjectGradeSummary.fromJson(Map<String, dynamic> json) {
    return SubjectGradeSummary(
      subjectId: json['subject_id'],
      subjectName: json['subject_name'],
      average: (json['average'] as num).toDouble(),
      gradeCount: json['grade_count'],
    );
  }
}

class GradeDetail {
  final int id;
  final String component;
  final double score;
  final double finalScore;
  final double kkm;
  final String? predicate;
  final String semester;
  final DateTime? createdAt;

  GradeDetail({
    required this.id,
    required this.component,
    required this.score,
    required this.finalScore,
    required this.kkm,
    this.predicate,
    required this.semester,
    this.createdAt,
  });

  factory GradeDetail.fromJson(Map<String, dynamic> json) {
    return GradeDetail(
      id: json['id'],
      component: json['component'] ?? '-',
      score: (json['score'] as num).toDouble(),
      finalScore: (json['final_score'] as num).toDouble(),
      kkm: (json['kkm'] as num).toDouble(),
      predicate: json['predicate'],
      semester: json['semester'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }
}

class SubjectGradeDetailResponse {
  final Map<String, dynamic> subject;
  final List<GradeDetail> grades;

  SubjectGradeDetailResponse({required this.subject, required this.grades});

  factory SubjectGradeDetailResponse.fromJson(Map<String, dynamic> json) {
    return SubjectGradeDetailResponse(
      subject: json['subject'] ?? {},
      grades: (json['grades'] as List? ?? [])
          .map((e) => GradeDetail.fromJson(e))
          .toList(),
    );
  }
}
