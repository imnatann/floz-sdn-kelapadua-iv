import '../../domain/entities/dashboard.dart';

class DashboardDto {
  static StudentDashboard fromJson(Map<String, dynamic> json) {
    final studentJson = json['student'];
    final statsJson = (json['stats'] as Map<String, dynamic>?) ?? const {};
    final schedules = (json['todays_schedules'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(_scheduleFromJson)
        .toList(growable: false);
    final announcements = (json['recent_announcements'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(_announcementFromJson)
        .toList(growable: false);

    return StudentDashboard(
      student: studentJson is Map<String, dynamic> ? _profileFromJson(studentJson) : null,
      stats: DashboardStats(
        attendancePercentage: (statsJson['attendance_percentage'] as num? ?? 0).toInt(),
      ),
      todaysSchedules: schedules,
      recentAnnouncements: announcements,
    );
  }

  static StudentDashboardProfile _profileFromJson(Map<String, dynamic> json) {
    return StudentDashboardProfile(
      id: json['id'] as int,
      name: json['name'] as String? ?? '-',
      className: json['class'] as String?,
      homeroomTeacher: json['homeroom_teacher'] as String?,
    );
  }

  static ScheduleItem _scheduleFromJson(Map<String, dynamic> json) {
    return ScheduleItem(
      id: json['id'] as int,
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '-',
      teacher: json['teacher']?.toString() ?? '-',
    );
  }

  static AnnouncementSummary _announcementFromJson(Map<String, dynamic> json) {
    return AnnouncementSummary(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
