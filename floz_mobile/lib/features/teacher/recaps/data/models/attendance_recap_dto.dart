import '../../domain/entities/attendance_recap.dart';

class AttendanceRecapDto {
  static AttendanceRecap fromJson(Map<String, dynamic> json) {
    final taJson = json['teaching_assignment'] as Map<String, dynamic>? ?? {};
    final studentsJson = json['students'] as List? ?? [];

    return AttendanceRecap(
      taInfo: RecapTaInfo(
        id: (taJson['id'] as num?)?.toInt() ?? 0,
        subjectName: taJson['subject_name'] as String? ?? '-',
        className: taJson['class_name'] as String? ?? '-',
      ),
      students: studentsJson
          .whereType<Map<String, dynamic>>()
          .map((s) => StudentAttendanceRecap(
                id: (s['id'] as num?)?.toInt() ?? 0,
                name: s['name'] as String? ?? '-',
                nis: s['nis']?.toString() ?? '-',
                hadir: (s['hadir'] as num?)?.toInt() ?? 0,
                sakit: (s['sakit'] as num?)?.toInt() ?? 0,
                izin: (s['izin'] as num?)?.toInt() ?? 0,
                alpha: (s['alpha'] as num?)?.toInt() ?? 0,
                total: (s['total'] as num?)?.toInt() ?? 0,
                percentage: (s['percentage'] as num?)?.toDouble() ?? 0.0,
              ))
          .toList(growable: false),
    );
  }
}
