import '../../../../../core/error/failure.dart';
import '../../../../../core/error/result.dart';
import '../../../../../core/network/api_exception.dart';
import '../../../../../core/storage/cache_box.dart';
import '../../domain/entities/report_card.dart';
import '../../domain/repositories/report_card_repository.dart';
import '../datasources/report_card_remote_datasource.dart';
import '../models/report_card_dto.dart';

class ReportCardRepositoryImpl implements ReportCardRepository {
  static const _listCacheKey = 'list';

  final ReportCardRemoteDataSource _remote;
  final CacheBox<dynamic> _cache;

  ReportCardRepositoryImpl({
    required ReportCardRemoteDataSource remote,
    required CacheBox<dynamic> cache,
  })  : _remote = remote,
        _cache = cache;

  @override
  Future<Result<List<ReportCardSummary>>> fetchList({bool forceRefresh = false}) async {
    // Always fetch from network first; cache is offline fallback only
    try {
      final data = await _remote.fetchList();
      await _cache.put(_listCacheKey, _listToJson(data));
      return Success(data);
    } on NetworkException catch (e) {
      final stale = await _cache.getStale(_listCacheKey);
      if (stale is List) {
        return Success(ReportCardDto.listFromJson(stale), stale: true);
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
  Future<Result<ReportCardDetail>> fetchDetail(int id) async {
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

  @override
  Future<Result<String>> fetchPdfUrl(int id) async {
    try {
      final url = await _remote.fetchPdfUrl(id);
      if (url == null) {
        return const FailureResult(ServerFailure('PDF URL not available'));
      }
      return Success(url);
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

  List<Map<String, dynamic>> _listToJson(List<ReportCardSummary> data) {
    return data
        .map((r) => {
              'id': r.id,
              'semester_name': r.semesterName,
              'academic_year': r.academicYear,
              'average_score': r.averageScore,
              'rank': r.rank,
              'published_at': r.publishedAt?.toIso8601String(),
            })
        .toList();
  }
}
