class ApiEndpoints {
  ApiEndpoints._();

  static const String authLogin  = '/auth/login';
  static const String authLogout = '/auth/logout';
  static const String authMe     = '/auth/me';

  static const String studentDashboard = '/student/dashboard';
  static const String studentSchedules  = '/student/schedules';
  static const String studentGrades = '/student/grades';
  static const String studentReportCards = '/student/report-cards';
  static const String studentAnnouncements = '/student/announcements';
  static const String studentAssignments = '/student/assignments';

  static const String teacherTeachingAssignments = '/teacher/teaching-assignments';
  static const String teacherMeetings = '/teacher/meetings';

  static String teacherAttendanceRecap(int taId) =>
      '/teacher/teaching-assignments/$taId/attendance-recap';
  static String teacherGradeRecap(int taId) =>
      '/teacher/teaching-assignments/$taId/grade-recap';

  static const String studentCourses = '/student/courses';
  static String studentCourseMeetings(int taId) =>
      '/student/courses/$taId/meetings';
  static String studentMeeting(int meetingId) =>
      '/student/meetings/$meetingId';

  static const String notifications = '/notifications';
  static String notificationRead(String id) => '/notifications/$id/read';
  static const String notificationsReadAll = '/notifications/read-all';
}
