class AssignmentItem {
  final int id;
  final String title;
  final String description;
  final DateTime? dueDate;
  final String subject;
  final String teacher;
  final String type;

  AssignmentItem({
    required this.id,
    required this.title,
    required this.description,
    this.dueDate,
    required this.subject,
    required this.teacher,
    required this.type,
  });

  factory AssignmentItem.fromJson(Map<String, dynamic> json) {
    return AssignmentItem(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'])
          : null,
      subject: json['subject'] ?? '-',
      teacher: json['teacher'] ?? '-',
      type: json['type'] ?? 'manual',
    );
  }
}

class AssignmentFile {
  final int id;
  final String fileName;
  final String filePath;
  final String fileUrl;

  AssignmentFile({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.fileUrl,
  });

  factory AssignmentFile.fromJson(Map<String, dynamic> json) {
    return AssignmentFile(
      id: json['id'],
      fileName: json['file_name'],
      filePath: json['file_path'],
      fileUrl: json['file_url'],
    );
  }
}

class AssignmentSubmission {
  final int id;
  final String status;
  final DateTime? submittedAt;
  final int? score;
  final String? teacherNotes;

  AssignmentSubmission({
    required this.id,
    required this.status,
    this.submittedAt,
    this.score,
    this.teacherNotes,
  });

  factory AssignmentSubmission.fromJson(Map<String, dynamic> json) {
    return AssignmentSubmission(
      id: json['id'],
      status: json['status'],
      submittedAt: json['submitted_at'] != null
          ? DateTime.parse(json['submitted_at'])
          : null,
      score: json['score'],
      teacherNotes: json['teacher_notes'],
    );
  }
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
  final AssignmentSubmission? submission;

  AssignmentDetail({
    required this.id,
    required this.title,
    required this.description,
    this.dueDate,
    required this.subject,
    required this.teacher,
    required this.type,
    required this.files,
    this.submission,
  });

  factory AssignmentDetail.fromJson(Map<String, dynamic> json) {
    return AssignmentDetail(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'])
          : null,
      subject: json['subject'] ?? '-',
      teacher: json['teacher'] ?? '-',
      type: json['type'] ?? 'manual',
      files: (json['files'] as List? ?? [])
          .map((e) => AssignmentFile.fromJson(e))
          .toList(),
      submission: json['submission'] != null
          ? AssignmentSubmission.fromJson(json['submission'])
          : null,
    );
  }
}
