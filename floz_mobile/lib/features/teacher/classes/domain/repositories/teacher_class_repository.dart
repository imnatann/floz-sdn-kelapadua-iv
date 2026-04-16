import '../../../../../core/error/result.dart';
import '../entities/class_meetings.dart';
import '../entities/teaching_assignment_summary.dart';

abstract class TeacherClassRepository {
  Future<Result<List<TeachingAssignmentSummary>>> fetchList();
  Future<Result<ClassMeetings>> fetchMeetings(int taId);
}
