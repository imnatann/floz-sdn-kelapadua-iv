import '../../../../../core/error/failure.dart';
import '../../../../../core/error/result.dart';
import '../../../../../core/network/api_exception.dart';
import '../../../../../core/storage/cache_box.dart';
import '../../domain/entities/class_meetings.dart';
import '../../domain/entities/teaching_assignment_summary.dart';
import '../../domain/repositories/teacher_class_repository.dart';
import '../datasources/teacher_class_remote_data_source.dart';
import '../models/teacher_class_dto.dart';

class TeacherClassRepositoryImpl implements TeacherClassRepository {
  static const _listCacheKey = 'list';

  final TeacherClassRemoteDataSource _remote;
  final CacheBox<dynamic> _cache;

  TeacherClassRepositoryImpl({
    required TeacherClassRemoteDataSource remote,
    required CacheBox<dynamic> cache,
  })  : _remote = remote,
        _cache = cache;

  @override
  Future<Result<List<TeachingAssignmentSummary>>> fetchList() async {
    // Network-first; cache is offline fallback only
    try {
      final data = await _remote.fetchList();
      await _cache.put(_listCacheKey, _listToJson(data));
      return Success(data);
    } on NetworkException catch (e) {
      final stale = await _cache.getStale(_listCacheKey);
      if (stale is List) {
        return Success(TeacherClassDto.listFromJson(stale), stale: true);
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
  Future<Result<ClassMeetings>> fetchMeetings(int taId) async {
    // Always fresh — no cache for meetings
    try {
      final data = await _remote.fetchMeetings(taId);
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

  List<Map<String, dynamic>> _listToJson(List<TeachingAssignmentSummary> data) {
    return data
        .map((ta) => {
              'id': ta.id,
              'subject_name': ta.subjectName,
              'class_name': ta.className,
              'academic_year': ta.academicYear,
              'student_count': ta.studentCount,
              'meeting_count': ta.meetingCount,
            })
        .toList();
  }
}
