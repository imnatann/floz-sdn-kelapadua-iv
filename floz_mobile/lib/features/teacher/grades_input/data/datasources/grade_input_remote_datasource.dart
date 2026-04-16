import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_endpoints.dart';
import '../../domain/entities/grade_roster.dart';
import '../models/grade_roster_dto.dart';

abstract class GradeInputRemoteDataSource {
  Future<GradeRoster> fetchRoster(int taId);
  Future<GradeRoster> submitGrades(int taId, List<Map<String, dynamic>> entries);
}

class GradeInputRemoteDataSourceImpl implements GradeInputRemoteDataSource {
  final ApiClient _client;
  GradeInputRemoteDataSourceImpl(this._client);

  @override
  Future<GradeRoster> fetchRoster(int taId) async {
    final res = await _client.get(
      '${ApiEndpoints.teacherTeachingAssignments}/$taId/grade-roster',
    );
    final body = res.data as Map<String, dynamic>;
    return GradeRosterDto.fromJson(body['data'] as Map<String, dynamic>);
  }

  @override
  Future<GradeRoster> submitGrades(int taId, List<Map<String, dynamic>> entries) async {
    final res = await _client.post(
      '${ApiEndpoints.teacherTeachingAssignments}/$taId/grades',
      body: {'entries': entries},
    );
    final body = res.data as Map<String, dynamic>;
    return GradeRosterDto.fromJson(body['data'] as Map<String, dynamic>);
  }
}
