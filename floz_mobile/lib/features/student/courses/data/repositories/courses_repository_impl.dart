import '../../../../../core/error/failure.dart';
import '../../../../../core/error/result.dart';
import '../../../../../core/network/api_exception.dart';
import '../../domain/entities/course.dart';
import '../../domain/entities/meeting_detail.dart';
import '../../domain/entities/meeting_summary.dart';
import '../../domain/repositories/courses_repository.dart';
import '../datasources/courses_remote_datasource.dart';

class CoursesRepositoryImpl implements CoursesRepository {
  final CoursesRemoteDataSource _remote;

  CoursesRepositoryImpl({required CoursesRemoteDataSource remote})
      : _remote = remote;

  @override
  Future<Result<List<Course>>> fetchCourses() =>
      _guard(() => _remote.fetchCourses());

  @override
  Future<Result<CourseMeetings>> fetchMeetings(int taId) =>
      _guard(() => _remote.fetchMeetings(taId));

  @override
  Future<Result<MeetingDetail>> fetchMeetingDetail(int meetingId) =>
      _guard(() => _remote.fetchMeetingDetail(meetingId));

  Future<Result<T>> _guard<T>(Future<T> Function() op) async {
    try {
      return Success(await op());
    } on NetworkException catch (e) {
      return FailureResult(NetworkFailure(e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(AuthFailure(e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(ForbiddenFailure(e.message));
    } on ValidationException catch (e) {
      return FailureResult(
        ValidationFailure(message: e.message, fieldErrors: e.errors),
      );
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message, statusCode: e.statusCode));
    } on ApiException catch (e) {
      return FailureResult(ServerFailure(e.message));
    }
  }
}
