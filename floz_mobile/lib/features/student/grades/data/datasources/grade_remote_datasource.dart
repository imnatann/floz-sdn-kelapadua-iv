import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_endpoints.dart';
import '../../domain/entities/student_grades.dart';
import '../models/grade_dto.dart';

abstract class GradeRemoteDataSource {
  Future<List<SubjectGradeSummary>> fetchList();
  Future<SubjectGradeInfo> fetchDetail(int subjectId);
}

class GradeRemoteDataSourceImpl implements GradeRemoteDataSource {
  final ApiClient _client;
  GradeRemoteDataSourceImpl(this._client);

  @override
  Future<List<SubjectGradeSummary>> fetchList() async {
    final res = await _client.get(ApiEndpoints.studentGrades);
    final body = res.data as Map<String, dynamic>;
    final data = body['data'] as List? ?? const [];
    return GradeDto.listFromJson(data);
  }

  @override
  Future<SubjectGradeInfo> fetchDetail(int subjectId) async {
    final res = await _client.get('${ApiEndpoints.studentGrades}/$subjectId');
    final body = res.data as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>? ?? {};
    return GradeDto.detailFromJson(data);
  }
}
