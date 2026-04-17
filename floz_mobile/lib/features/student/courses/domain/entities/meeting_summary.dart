class CourseInfo {
  final int id;
  final String subjectName;
  final String teacherName;
  final String className;

  const CourseInfo({
    required this.id,
    required this.subjectName,
    required this.teacherName,
    required this.className,
  });
}

class MeetingSummary {
  final int id;
  final int meetingNumber;
  final String title;
  final String? description;
  final bool isLocked;
  final int materialCount;

  const MeetingSummary({
    required this.id,
    required this.meetingNumber,
    required this.title,
    this.description,
    required this.isLocked,
    required this.materialCount,
  });
}

class CourseMeetings {
  final CourseInfo course;
  final List<MeetingSummary> meetings;

  const CourseMeetings({
    required this.course,
    required this.meetings,
  });
}
