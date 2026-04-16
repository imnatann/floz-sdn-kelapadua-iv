import '../../../../../core/error/failure.dart';
import '../../../../../core/error/result.dart';
import '../../../../../core/network/api_exception.dart';
import '../../../../../core/storage/cache_box.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../datasources/announcement_remote_datasource.dart';
import '../models/announcement_dto.dart';

class AnnouncementRepositoryImpl implements AnnouncementRepository {
  static const _listCacheKey = 'list';

  final AnnouncementRemoteDataSource _remote;
  final CacheBox<dynamic> _cache;

  AnnouncementRepositoryImpl({
    required AnnouncementRemoteDataSource remote,
    required CacheBox<dynamic> cache,
  })  : _remote = remote,
        _cache = cache;

  @override
  Future<Result<List<AnnouncementSummary>>> fetchList({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await _cache.get(_listCacheKey);
      if (cached is List) {
        return Success(AnnouncementDto.listFromJson(cached));
      }
    }

    try {
      final data = await _remote.fetchList();
      await _cache.put(_listCacheKey, _listToJson(data));
      return Success(data);
    } on NetworkException catch (e) {
      final stale = await _cache.getStale(_listCacheKey);
      if (stale is List) {
        return Success(AnnouncementDto.listFromJson(stale), stale: true);
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
  Future<Result<AnnouncementDetail>> fetchDetail(int id) async {
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

  List<Map<String, dynamic>> _listToJson(List<AnnouncementSummary> data) {
    return data
        .map((a) => {
              'id': a.id,
              'title': a.title,
              'excerpt': a.excerpt,
              'type': a.type,
              'is_pinned': a.isPinned,
              'cover_image_url': a.coverImageUrl,
              'created_at': a.createdAt?.toIso8601String(),
            })
        .toList();
  }
}
