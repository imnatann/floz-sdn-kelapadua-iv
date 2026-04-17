import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_endpoints.dart';
import '../../domain/entities/course.dart';
import '../../domain/entities/meeting_detail.dart';
import '../../domain/entities/meeting_summary.dart';
import '../models/course_dto.dart';
import '../models/meeting_detail_dto.dart';
import '../models/meetings_dto.dart';

abstract class CoursesRemoteDataSource {
  Future<List<Course>> fetchCourses();
  Future<CourseMeetings> fetchMeetings(int taId);
  Future<MeetingDetail> fetchMeetingDetail(int meetingId);
}

class CoursesRemoteDataSourceImpl implements CoursesRemoteDataSource {
  final ApiClient _client;

  CoursesRemoteDataSourceImpl(this._client);

  @override
  Future<List<Course>> fetchCourses() async {
    final res = await _client.get(ApiEndpoints.studentCourses);
    final body = res.data as Map<String, dynamic>;
    final data = body['data'] as List? ?? const [];
    return CourseDto.listFromJson(data);
  }

  @override
  Future<CourseMeetings> fetchMeetings(int taId) async {
    final res = await _client.get(ApiEndpoints.studentCourseMeetings(taId));
    final body = res.data as Map<String, dynamic>;
    return MeetingsDto.fromJson(body['data'] as Map<String, dynamic>);
  }

  @override
  Future<MeetingDetail> fetchMeetingDetail(int meetingId) async {
    final res = await _client.get(ApiEndpoints.studentMeeting(meetingId));
    final body = res.data as Map<String, dynamic>;
    return MeetingDetailDto.fromJson(body['data'] as Map<String, dynamic>);
  }
}
