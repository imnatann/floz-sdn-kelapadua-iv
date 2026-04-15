class StudentDashboardData {
  final Map<String, dynamic>? student;
  final DashboardStats stats;
  final List<TodaySchedule> todaysSchedules;
  final List<AnnouncementItem> recentAnnouncements;

  StudentDashboardData({
    required this.student,
    required this.stats,
    required this.todaysSchedules,
    required this.recentAnnouncements,
  });

  factory StudentDashboardData.fromJson(Map<String, dynamic> json) {
    return StudentDashboardData(
      student: json['student'],
      stats: DashboardStats.fromJson(json['stats'] ?? {}),
      todaysSchedules: (json['todays_schedules'] as List? ?? [])
          .map((e) => TodaySchedule.fromJson(e))
          .toList(),
      recentAnnouncements: (json['recent_announcements'] as List? ?? [])
          .map((e) => AnnouncementItem.fromJson(e))
          .toList(),
    );
  }
}

class DashboardStats {
  final int attendancePercentage;

  DashboardStats({required this.attendancePercentage});

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      attendancePercentage: json['attendance_percentage'] ?? 0,
    );
  }
}

class TodaySchedule {
  final String id;
  final String startTime;
  final String endTime;
  final String subject;
  final String teacher;

  TodaySchedule({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.subject,
    required this.teacher,
  });

  factory TodaySchedule.fromJson(Map<String, dynamic> json) {
    return TodaySchedule(
      id: json['id'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      subject: json['subject'],
      teacher: json['teacher'],
    );
  }
}

class AnnouncementItem {
  final int id;
  final String title;
  final String content;
  final DateTime createdAt;

  AnnouncementItem({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  factory AnnouncementItem.fromJson(Map<String, dynamic> json) {
    return AnnouncementItem(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
