class StudentDashboard {
  final StudentDashboardProfile? student;
  final DashboardStats stats;
  final List<ScheduleItem> todaysSchedules;
  final List<AnnouncementSummary> recentAnnouncements;

  const StudentDashboard({
    required this.student,
    required this.stats,
    required this.todaysSchedules,
    required this.recentAnnouncements,
  });
}

class StudentDashboardProfile {
  final int id;
  final String name;
  final String? className;
  final String? homeroomTeacher;

  const StudentDashboardProfile({
    required this.id,
    required this.name,
    required this.className,
    required this.homeroomTeacher,
  });
}

class DashboardStats {
  final int attendancePercentage;

  const DashboardStats({required this.attendancePercentage});
}

class ScheduleItem {
  final String id;
  final String startTime;
  final String endTime;
  final String subject;
  final String teacher;

  const ScheduleItem({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.subject,
    required this.teacher,
  });
}

class AnnouncementSummary {
  final int id;
  final String title;
  final String content;
  final DateTime createdAt;

  const AnnouncementSummary({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
  });
}
