class ReportCardSummary {
  final int id;
  final String semesterName;
  final String academicYear;
  final double averageScore;
  final int? rank;
  final DateTime? publishedAt;

  ReportCardSummary({
    required this.id,
    required this.semesterName,
    required this.academicYear,
    required this.averageScore,
    this.rank,
    this.publishedAt,
  });

  factory ReportCardSummary.fromJson(Map<String, dynamic> json) {
    return ReportCardSummary(
      id: json['id'],
      semesterName: json['semester_name'] ?? '-',
      academicYear: json['academic_year'] ?? '-',
      averageScore: (json['average_score'] as num).toDouble(),
      rank: json['rank'],
      publishedAt: json['published_at'] != null
          ? DateTime.parse(json['published_at'])
          : null,
    );
  }
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

  ReportCardDetail({
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

  factory ReportCardDetail.fromJson(Map<String, dynamic> json) {
    return ReportCardDetail(
      id: json['id'],
      semesterName: json['semester_name'] ?? '-',
      academicYear: json['academic_year'] ?? '-',
      className: json['class_name'] ?? '-',
      averageScore: (json['average_score'] as num).toDouble(),
      totalScore: (json['total_score'] as num).toDouble(),
      rank: json['rank'],
      attendancePresent: json['attendance_present'] ?? 0,
      attendanceSick: json['attendance_sick'] ?? 0,
      attendancePermit: json['attendance_permit'] ?? 0,
      attendanceAbsent: json['attendance_absent'] ?? 0,
      achievements: json['achievements'],
      notes: json['notes'],
      behaviorNotes: json['behavior_notes'],
      homeroomComment: json['homeroom_comment'],
      principalComment: json['principal_comment'],
      pdfUrl: json['pdf_url'],
      publishedAt: json['published_at'] != null
          ? DateTime.parse(json['published_at'])
          : null,
    );
  }
}
