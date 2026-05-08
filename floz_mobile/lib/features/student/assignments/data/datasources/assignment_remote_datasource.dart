import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_endpoints.dart';
import '../../domain/entities/assignment.dart';
import '../models/assignment_dto.dart';

abstract class AssignmentRemoteDataSource {
  Future<List<AssignmentSummary>> fetchList({String status = 'upcoming'});
  Future<AssignmentDetail> fetchDetail(int id);
  Future<SubmissionResult> submitAssignment(int id, {String? answerText, String? answerLink});
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

  @override
  Future<SubmissionResult> submitAssignment(int id, {String? answerText, String? answerLink}) async {
    final res = await _client.post(
      ApiEndpoints.studentAssignmentSubmit(id),
      body: {'answer_text': answerText, 'answer_link': answerLink},
    );
    final body = res.data as Map<String, dynamic>;
    return SubmissionResult.fromJson(body['data'] as Map<String, dynamic>);
  }
}
