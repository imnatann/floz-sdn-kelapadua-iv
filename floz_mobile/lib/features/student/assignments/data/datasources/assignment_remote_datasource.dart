import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_endpoints.dart';
import '../../domain/entities/assignment.dart';
import '../models/assignment_dto.dart';

abstract class AssignmentRemoteDataSource {
  Future<List<AssignmentSummary>> fetchList({String status = 'upcoming'});
  Future<AssignmentDetail> fetchDetail(int id);
}

class AssignmentRemoteDataSourceImpl implements AssignmentRemoteDataSource {
  final ApiClient _client;
  AssignmentRemoteDataSourceImpl(this._client);

  @override
  Future<List<AssignmentSummary>> fetchList({String status = 'upcoming'}) async {
    final res = await _client.get(
      ApiEndpoints.studentAssignments,
      query: {'status': status},
    );
    final body = res.data as Map<String, dynamic>;
    final data = body['data'] as List? ?? const [];
    return AssignmentDto.listFromJson(data);
  }

  @override
  Future<AssignmentDetail> fetchDetail(int id) async {
    final res = await _client.get('${ApiEndpoints.studentAssignments}/$id');
    final body = res.data as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>? ?? {};
    return AssignmentDto.detailFromJson(data);
  }
}
