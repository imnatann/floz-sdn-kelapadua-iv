class GradeRoster {
  final int taId;
  final String subjectName;
  final String className;
  final List<StudentGrade> students;

  const GradeRoster({
    required this.taId,
    required this.subjectName,
    required this.className,
    required this.students,
  });
}

class StudentGrade {
  final int id;
  final String name;
  final String nis;
  final double? dailyTestAvg;
  final double? midTest;
  final double? finalTest;
  final double? finalScore;
  final String? predicate;

  const StudentGrade({
    required this.id,
    required this.name,
    required this.nis,
    this.dailyTestAvg,
    this.midTest,
    this.finalTest,
    this.finalScore,
    this.predicate,
  });
}
