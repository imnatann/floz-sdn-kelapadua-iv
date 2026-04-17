import '../../../../../core/error/result.dart';
import '../entities/course.dart';
import '../entities/meeting_detail.dart';
import '../entities/meeting_summary.dart';

abstract class CoursesRepository {
  Future<Result<List<Course>>> fetchCourses();
  Future<Result<CourseMeetings>> fetchMeetings(int taId);
  Future<Result<MeetingDetail>> fetchMeetingDetail(int meetingId);
}
