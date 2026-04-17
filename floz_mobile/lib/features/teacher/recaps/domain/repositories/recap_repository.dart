import '../../../../../core/error/result.dart';
import '../entities/attendance_recap.dart';
import '../entities/grade_recap.dart';

abstract class RecapRepository {
  Future<Result<AttendanceRecap>> fetchAttendanceRecap(int taId);
  Future<Result<GradeRecap>> fetchGradeRecap(int taId);
}
