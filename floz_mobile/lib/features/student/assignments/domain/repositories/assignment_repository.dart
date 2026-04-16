import '../../../../../core/error/result.dart';
import '../entities/assignment.dart';

abstract class AssignmentRepository {
  Future<Result<List<AssignmentSummary>>> fetchList({String status = 'upcoming', bool forceRefresh = false});
  Future<Result<AssignmentDetail>> fetchDetail(int id);
}
