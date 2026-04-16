import '../../../../../core/error/failure.dart';
import '../../../../../core/error/result.dart';
import '../../../../../core/network/api_exception.dart';
import '../../../../../core/storage/cache_box.dart';
import '../../domain/entities/dashboard.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_remote_datasource.dart';
import '../models/dashboard_dto.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  static const _cacheKey = 'main';

  final DashboardRemoteDataSource _remote;
  final CacheBox<dynamic> _cache;

  DashboardRepositoryImpl({
    required DashboardRemoteDataSource remote,
    required CacheBox<dynamic> cache,
  })  : _remote = remote,
        _cache = cache;

  @override
  Future<Result<StudentDashboard>> fetch({bool forceRefresh = false}) async {
    // Always fetch from network first; cache is offline fallback only
    try {
      final data = await _remote.fetch();
      await _cache.put(_cacheKey, _toJson(data));
      return Success(data);
    } on NetworkException catch (e) {
      // Network failed — try stale cache as fallback
      final stale = await _cache.getStale(_cacheKey);
      if (stale is Map) {
        return Success(
          DashboardDto.fromJson(Map<String, dynamic>.from(stale)),
          stale: true,
        );
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

  Map<String, dynamic> _toJson(StudentDashboard d) {
    return {
      'student': d.student == null
          ? null
          : {
              'id': d.student!.id,
              'name': d.student!.name,
              'class': d.student!.className,
              'homeroom_teacher': d.student!.homeroomTeacher,
            },
      'stats': {'attendance_percentage': d.stats.attendancePercentage},
      'todays_schedules': d.todaysSchedules
          .map((s) => {
                'id': s.id,
                'start_time': s.startTime,
                'end_time': s.endTime,
                'subject': s.subject,
                'teacher': s.teacher,
              })
          .toList(),
      'recent_announcements': d.recentAnnouncements
          .map((a) => {
                'id': a.id,
                'title': a.title,
                'content': a.content,
                'created_at': a.createdAt.toIso8601String(),
              })
          .toList(),
    };
  }
}
