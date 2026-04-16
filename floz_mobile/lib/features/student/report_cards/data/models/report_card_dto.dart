import '../../domain/entities/report_card.dart';

class ReportCardDto {
  static List<ReportCardSummary> listFromJson(List<dynamic> json) {
    return json
        .whereType<Map<String, dynamic>>()
        .map((j) => ReportCardSummary(
              id: (j['id'] as num?)?.toInt() ?? 0,
              semesterName: j['semester_name'] as String? ?? '-',
              academicYear: j['academic_year'] as String? ?? '-',
              averageScore: (j['average_score'] as num?)?.toDouble() ?? 0,
              rank: (j['rank'] as num?)?.toInt(),
              publishedAt: DateTime.tryParse(j['published_at']?.toString() ?? ''),
            ))
        .toList(growable: false);
  }

  static ReportCardDetail detailFromJson(Map<String, dynamic> j) {
    return ReportCardDetail(
      id: (j['id'] as num?)?.toInt() ?? 0,
      semesterName: j['semester_name'] as String? ?? '-',
      academicYear: j['academic_year'] as String? ?? '-',
      className: j['class_name'] as String? ?? '-',
      averageScore: (j['average_score'] as num?)?.toDouble() ?? 0,
      totalScore: (j['total_score'] as num?)?.toDouble() ?? 0,
      rank: (j['rank'] as num?)?.toInt(),
      attendancePresent: (j['attendance_present'] as num?)?.toInt() ?? 0,
      attendanceSick: (j['attendance_sick'] as num?)?.toInt() ?? 0,
      attendancePermit: (j['attendance_permit'] as num?)?.toInt() ?? 0,
      attendanceAbsent: (j['attendance_absent'] as num?)?.toInt() ?? 0,
      achievements: j['achievements'] as String?,
      notes: j['notes'] as String?,
      behaviorNotes: j['behavior_notes'] as String?,
      homeroomComment: j['homeroom_comment'] as String?,
      principalComment: j['principal_comment'] as String?,
      pdfUrl: j['pdf_url'] as String?,
      publishedAt: DateTime.tryParse(j['published_at']?.toString() ?? ''),
    );
  }
}
