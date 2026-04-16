import '../../../../../core/error/result.dart';
import '../entities/attendance_roster.dart';

abstract class AttendanceRepository {
  Future<Result<AttendanceRoster>> fetchRoster(int meetingId);
  Future<Result<AttendanceRoster>> submitAttendance(
    int meetingId,
    List<Map<String, dynamic>> entries,
  );
}
