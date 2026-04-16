import '../../../../../core/error/failure.dart';
import '../../../../../core/error/result.dart';
import '../../../../../core/network/api_exception.dart';
import '../../../../../core/storage/cache_box.dart';
import '../../domain/entities/assignment.dart';
import '../../domain/repositories/assignment_repository.dart';
import '../datasources/assignment_remote_datasource.dart';
import '../models/assignment_dto.dart';

class AssignmentRepositoryImpl implements AssignmentRepository {
  final AssignmentRemoteDataSource _remote;
  final CacheBox<dynamic> _cache;

  AssignmentRepositoryImpl({
    required AssignmentRemoteDataSource remote,
    required CacheBox<dynamic> cache,
  })  : _remote = remote,
        _cache = cache;

  String _listCacheKey(String status) => 'list_$status';

  @override
  Future<Result<List<AssignmentSummary>>> fetchList({
    String status = 'upcoming',
    bool forceRefresh = false,
  }) async {
    final cacheKey = _listCacheKey(status);

    // Always fetch from network first; cache is offline fallback only
    try {
      final data = await _remote.fetchList(status: status);
      await _cache.put(cacheKey, _listToJson(data));
      return Success(data);
    } on NetworkException catch (e) {
      final stale = await _cache.getStale(cacheKey);
      if (stale is List) {
        return Success(AssignmentDto.listFromJson(stale), stale: true);
      }
      return FailureResult(NetworkFailure(e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(AuthFailure(e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(ForbiddenFailure(e.message));
    } on ApiException catch (e) {
      return FailureResult(ServerFailure(e.message));
    }
  }

  @override
  Future<Result<AssignmentDetail>> fetchDetail(int id) async {
    try {
      final data = await _remote.fetchDetail(id);
      return Success(data);
    } on NetworkException catch (e) {
      return FailureResult(NetworkFailure(e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(AuthFailure(e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(ForbiddenFailure(e.message));
    } on ApiException catch (e) {
      return FailureResult(ServerFailure(e.message));
    }
  }

  List<Map<String, dynamic>> _listToJson(List<AssignmentSummary> data) {
    return data
        .map((a) => {
              'id': a.id,
              'title': a.title,
              'description': a.description,
              'due_date': a.dueDate?.toIso8601String(),
              'subject': a.subject,
              'teacher': a.teacher,
              'type': a.type,
            })
        .toList();
  }
}
