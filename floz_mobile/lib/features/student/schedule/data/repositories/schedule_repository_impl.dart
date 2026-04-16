import '../../../../../core/error/failure.dart';
import '../../../../../core/error/result.dart';
import '../../../../../core/network/api_exception.dart';
import '../../../../../core/storage/cache_box.dart';
import '../../domain/entities/weekly_schedule.dart';
import '../../domain/repositories/schedule_repository.dart';
import '../datasources/schedule_remote_datasource.dart';
import '../models/schedule_dto.dart';

class ScheduleRepositoryImpl implements ScheduleRepository {
  static const _cacheKey = 'main';

  final ScheduleRemoteDataSource _remote;
  final CacheBox<dynamic> _cache;

  ScheduleRepositoryImpl({
    required ScheduleRemoteDataSource remote,
    required CacheBox<dynamic> cache,
  })  : _remote = remote,
        _cache = cache;

  @override
  Future<Result<WeeklySchedule>> fetch({bool forceRefresh = false}) async {
    // Always fetch from network first; cache is offline fallback only
    try {
      final data = await _remote.fetch();
      await _cache.put(_cacheKey, _toJson(data));
      return Success(data);
    } on NetworkException catch (e) {
      final stale = await _cache.getStale(_cacheKey);
      if (stale is List) {
        return Success(ScheduleDto.fromJson(stale), stale: true);
      }
      return FailureResult(NetworkFailure(e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(AuthFailure(e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(ForbiddenFailure(e.message));
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message, statusCode: e.statusCode));
    } on ApiException catch (e) {
      return FailureResult(ServerFailure(e.message));
    }
  }

  List<Map<String, dynamic>> _toJson(WeeklySchedule s) {
    return s.days
        .map((d) => {
              'day': d.day,
              'day_name': d.dayName,
              'items': d.items
                  .map((e) => {
                        'id': e.id,
                        'start_time': e.startTime,
                        'end_time': e.endTime,
                        'subject': e.subject,
                        'teacher': e.teacher,
                      })
                  .toList(),
            })
        .toList();
  }
}
