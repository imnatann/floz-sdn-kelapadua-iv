import '../../../../../core/error/failure.dart';
import '../../../../../core/error/result.dart';
import '../../../../../core/network/api_exception.dart';
import '../../../../../core/storage/cache_box.dart';
import '../../domain/entities/student_grades.dart';
import '../../domain/repositories/grade_repository.dart';
import '../datasources/grade_remote_datasource.dart';
import '../models/grade_dto.dart';

class GradeRepositoryImpl implements GradeRepository {
  static const _listCacheKey = 'list';

  final GradeRemoteDataSource _remote;
  final CacheBox<dynamic> _cache;

  GradeRepositoryImpl({
    required GradeRemoteDataSource remote,
    required CacheBox<dynamic> cache,
  })  : _remote = remote,
        _cache = cache;

  @override
  Future<Result<List<SubjectGradeSummary>>> fetchList({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await _cache.get(_listCacheKey);
      if (cached is List) {
        return Success(GradeDto.listFromJson(cached));
      }
    }

    try {
      final data = await _remote.fetchList();
      await _cache.put(_listCacheKey, _listToJson(data));
      return Success(data);
    } on NetworkException catch (e) {
      final stale = await _cache.getStale(_listCacheKey);
      if (stale is List) {
        return Success(GradeDto.listFromJson(stale), stale: true);
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
  Future<Result<SubjectGradeInfo>> fetchDetail(int subjectId) async {
    try {
      final data = await _remote.fetchDetail(subjectId);
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

  List<Map<String, dynamic>> _listToJson(List<SubjectGradeSummary> data) {
    return data
        .map((g) => {
              'subject_id': g.subjectId,
              'subject_name': g.subjectName,
              'average': g.average,
              'grade_count': g.gradeCount,
              'kkm': g.kkm,
            })
        .toList();
  }
}
