class ClassMeetings {
  final int taId;
  final String subjectName;
  final String className;
  final List<MeetingSummary> meetings;

  const ClassMeetings({
    required this.taId,
    required this.subjectName,
    required this.className,
    required this.meetings,
  });
}

class MeetingSummary {
  final int id;
  final int meetingNumber;
  final String title;
  final String? description;
  final bool isLocked;
  final int materialCount;
  final int assignmentCount;

  const MeetingSummary({
    required this.id,
    required this.meetingNumber,
    required this.title,
    this.description,
    required this.isLocked,
    required this.materialCount,
    required this.assignmentCount,
  });
}
