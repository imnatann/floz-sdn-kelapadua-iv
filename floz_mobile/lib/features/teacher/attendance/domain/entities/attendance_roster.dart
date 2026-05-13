class AttendanceRoster {
  final MeetingInfo meeting;
  final ClassInfo classInfo;
  final SubjectInfo subject;
  final List<StudentAttendance> students;

  const AttendanceRoster({
    required this.meeting,
    required this.classInfo,
    required this.subject,
    required this.students,
  });
}

/// Daily class attendance roster — returned by the homeroom-teacher daily endpoints.
class DailyAttendanceRoster {
  final int meetingNumber;
  final String date;
  final ClassInfo classInfo;
  final List<StudentAttendance> students;

  const DailyAttendanceRoster({
    required this.meetingNumber,
    required this.date,
    required this.classInfo,
    required this.students,
  });
}

class MeetingInfo {
  final int id;
  final int meetingNumber;
  final String title;
  const MeetingInfo({required this.id, required this.meetingNumber, required this.title});
}

class ClassInfo {
  final int id;
  final String name;
  const ClassInfo({required this.id, required this.name});
}

class SubjectInfo {
  final int id;
  final String name;
  const SubjectInfo({required this.id, required this.name});
}

class StudentAttendance {
  final int id;
  final String name;
  final String nis;
  final String? status; // null = not yet recorded; 'hadir'|'sakit'|'izin'|'alpha'
  final String? note;

  const StudentAttendance({
    required this.id,
    required this.name,
    required this.nis,
    this.status,
    this.note,
  });
}
