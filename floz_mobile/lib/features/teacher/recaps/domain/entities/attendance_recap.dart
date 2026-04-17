class RecapTaInfo {
  final int id;
  final String subjectName;
  final String className;

  const RecapTaInfo({
    required this.id,
    required this.subjectName,
    required this.className,
  });
}

class AttendanceRecap {
  final RecapTaInfo taInfo;
  final List<StudentAttendanceRecap> students;

  const AttendanceRecap({
    required this.taInfo,
    required this.students,
  });
}

class StudentAttendanceRecap {
  final int id;
  final String name;
  final String nis;
  final int hadir;
  final int sakit;
  final int izin;
  final int alpha;
  final int total;
  final double percentage;

  const StudentAttendanceRecap({
    required this.id,
    required this.name,
    required this.nis,
    required this.hadir,
    required this.sakit,
    required this.izin,
    required this.alpha,
    required this.total,
    required this.percentage,
  });
}
