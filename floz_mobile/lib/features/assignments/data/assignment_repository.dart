import '../domain/assignment_models.dart';
import 'assignment_api.dart';

class AssignmentRepository {
  final AssignmentApi _api;

  AssignmentRepository(this._api);

  Future<List<AssignmentItem>> getAssignments({
    String status = 'upcoming',
  }) async {
    final data = await _api.getAssignments(status: status);
    return data.map((e) => AssignmentItem.fromJson(e)).toList();
  }

  Future<AssignmentDetail> getAssignmentDetail(int id) async {
    final data = await _api.getAssignmentDetail(id);
    return AssignmentDetail.fromJson(data);
  }
}
