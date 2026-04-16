import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_endpoints.dart';
import '../../domain/entities/class_meetings.dart';
import '../../domain/entities/teaching_assignment_summary.dart';
import '../models/teacher_class_dto.dart';

abstract class TeacherClassRemoteDataSource {
  Future<List<TeachingAssignmentSummary>> fetchList();
  Future<ClassMeetings> fetchMeetings(int taId);
}

class TeacherClassRemoteDataSourceImpl implements TeacherClassRemoteDataSource {
  final ApiClient _client;
  TeacherClassRemoteDataSourceImpl(this._client);

  @override
  Future<List<TeachingAssignmentSummary>> fetchList() async {
    final res = await _client.get(ApiEndpoints.teacherTeachingAssignments);
    final body = res.data as Map<String, dynamic>;
    final data = body['data'] as List? ?? const [];
    return TeacherClassDto.listFromJson(data);
  }

  @override
  Future<ClassMeetings> fetchMeetings(int taId) async {
    final res = await _client
        .get('${ApiEndpoints.teacherTeachingAssignments}/$taId/meetings');
    final body = res.data as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>? ?? {};
    return TeacherClassDto.meetingsFromJson(data);
  }
}
