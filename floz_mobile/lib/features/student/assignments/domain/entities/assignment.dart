class AssignmentSummary {
  final int id;
  final String title;
  final String description;
  final DateTime? dueDate;
  final String subject;
  final String teacher;
  final String type;

  const AssignmentSummary({
    required this.id, required this.title, required this.description,
    this.dueDate, required this.subject, required this.teacher, required this.type,
  });

  bool get isOverdue => dueDate != null && dueDate!.isBefore(DateTime.now());
}

class AssignmentFile {
  final int id;
  final String fileName;
  final String fileUrl;

  const AssignmentFile({required this.id, required this.fileName, required this.fileUrl});
}

class SubmissionInfo {
  final int id;
  final String status; // 'submitted' | 'graded'
  final DateTime? submittedAt;
  final int? score;
  final String? teacherNotes;

  const SubmissionInfo({
    required this.id, required this.status, this.submittedAt, this.score, this.teacherNotes,
  });
}

class AssignmentDetail {
  final int id;
  final String title;
  final String description;
  final DateTime? dueDate;
  final String subject;
  final String teacher;
  final String type;
  final List<AssignmentFile> files;
  final SubmissionInfo? submission;

  const AssignmentDetail({
    required this.id, required this.title, required this.description,
    this.dueDate, required this.subject, required this.teacher, required this.type,
    required this.files, this.submission,
  });

  bool get isOverdue => dueDate != null && dueDate!.isBefore(DateTime.now());
}
