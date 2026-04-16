class ReportCardSummary {
  final int id;
  final String semesterName;
  final String academicYear;
  final double averageScore;
  final int? rank;
  final DateTime? publishedAt;

  const ReportCardSummary({
    required this.id,
    required this.semesterName,
    required this.academicYear,
    required this.averageScore,
    this.rank,
    this.publishedAt,
  });
}

class ReportCardDetail {
  final int id;
  final String semesterName;
  final String academicYear;
  final String className;
  final double averageScore;
  final double totalScore;
  final int? rank;
  final int attendancePresent;
  final int attendanceSick;
  final int attendancePermit;
  final int attendanceAbsent;
  final String? achievements;
  final String? notes;
  final String? behaviorNotes;
  final String? homeroomComment;
  final String? principalComment;
  final String? pdfUrl;
  final DateTime? publishedAt;

  const ReportCardDetail({
    required this.id,
    required this.semesterName,
    required this.academicYear,
    required this.className,
    required this.averageScore,
    required this.totalScore,
    this.rank,
    required this.attendancePresent,
    required this.attendanceSick,
    required this.attendancePermit,
    required this.attendanceAbsent,
    this.achievements,
    this.notes,
    this.behaviorNotes,
    this.homeroomComment,
    this.principalComment,
    this.pdfUrl,
    this.publishedAt,
  });

  int get totalAttendance =>
      attendancePresent + attendanceSick + attendancePermit + attendanceAbsent;
}
