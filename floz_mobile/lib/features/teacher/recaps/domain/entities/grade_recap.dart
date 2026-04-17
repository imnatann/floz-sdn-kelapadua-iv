import 'attendance_recap.dart';

class GradeRecap {
  final RecapTaInfo taInfo;
  final List<StudentGradeRecap> students;

  const GradeRecap({
    required this.taInfo,
    required this.students,
  });
}

class StudentGradeRecap {
  final int id;
  final String name;
  final String nis;
  final double? dailyTestAvg;
  final double? midTest;
  final double? finalTest;
  final double? finalScore;
  final String? predicate;

  const StudentGradeRecap({
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
