class SubjectGradeSummary {
  final int subjectId;
  final String subjectName;
  final double average;
  final int gradeCount;
  final double kkm;

  const SubjectGradeSummary({
    required this.subjectId,
    required this.subjectName,
    required this.average,
    required this.gradeCount,
    required this.kkm,
  });

  bool get aboveKkm => average >= kkm;
}

class GradeDetail {
  final int id;
  final double dailyTestAvg;
  final double midTest;
  final double finalTest;
  final double? knowledgeScore;
  final double? skillScore;
  final double finalScore;
  final String predicate;
  final String semester;
  final String? notes;
  final DateTime? createdAt;

  const GradeDetail({
    required this.id,
    required this.dailyTestAvg,
    required this.midTest,
    required this.finalTest,
    this.knowledgeScore,
    this.skillScore,
    required this.finalScore,
    required this.predicate,
    required this.semester,
    this.notes,
    this.createdAt,
  });
}

class SubjectGradeInfo {
  final int subjectId;
  final String subjectName;
  final double kkm;
  final List<GradeDetail> grades;

  const SubjectGradeInfo({
    required this.subjectId,
    required this.subjectName,
    required this.kkm,
    required this.grades,
  });
}
