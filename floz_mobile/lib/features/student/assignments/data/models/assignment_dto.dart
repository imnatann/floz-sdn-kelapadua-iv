import '../../domain/entities/assignment.dart';

class AssignmentDto {
  static List<AssignmentSummary> listFromJson(List<dynamic> json) {
    return json
        .whereType<Map<String, dynamic>>()
        .map((j) => AssignmentSummary(
              id: (j['id'] as num?)?.toInt() ?? 0,
              title: j['title'] as String? ?? '',
              description: j['description'] as String? ?? '',
              dueDate: DateTime.tryParse(j['due_date']?.toString() ?? ''),
              subject: j['subject'] as String? ?? '',
              teacher: j['teacher'] as String? ?? '',
              type: j['type'] as String? ?? '',
            ))
        .toList(growable: false);
  }

  static AssignmentDetail detailFromJson(Map<String, dynamic> json) {
    final rawFiles = json['files'] as List? ?? const [];
    final files = rawFiles
        .whereType<Map<String, dynamic>>()
        .map((f) => AssignmentFile(
              id: (f['id'] as num?)?.toInt() ?? 0,
              fileName: f['file_name'] as String? ?? '',
              fileUrl: f['file_url'] as String? ?? '',
            ))
        .toList(growable: false);

    SubmissionInfo? submission;
    final rawSub = json['submission'];
    if (rawSub is Map<String, dynamic>) {
      submission = SubmissionInfo(
        id: (rawSub['id'] as num?)?.toInt() ?? 0,
        status: rawSub['status'] as String? ?? '',
        submittedAt: DateTime.tryParse(rawSub['submitted_at']?.toString() ?? ''),
        score: (rawSub['score'] as num?)?.toInt(),
        teacherNotes: rawSub['teacher_notes'] as String?,
      );
    }

    return AssignmentDetail(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      dueDate: DateTime.tryParse(json['due_date']?.toString() ?? ''),
      subject: json['subject'] as String? ?? '',
      teacher: json['teacher'] as String? ?? '',
      type: json['type'] as String? ?? '',
      files: files,
      submission: submission,
    );
  }
}
