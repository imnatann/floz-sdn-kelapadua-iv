import '../../../../../core/error/failure.dart';
import '../../../../../core/error/result.dart';
import '../../../../../core/network/api_exception.dart';
import '../../domain/entities/attendance_recap.dart';
import '../../domain/entities/grade_recap.dart';
import '../../domain/repositories/recap_repository.dart';
import '../datasources/recap_remote_datasource.dart';

class RecapRepositoryImpl implements RecapRepository {
  final RecapRemoteDataSource _remote;

  RecapRepositoryImpl({required RecapRemoteDataSource remote})
      : _remote = remote;

  @override
  Future<Result<AttendanceRecap>> fetchAttendanceRecap(int taId) async {
    try {
      final data = await _remote.fetchAttendanceRecap(taId);
      return Success(data);
    } on NetworkException catch (e) {
      return FailureResult(NetworkFailure(e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(AuthFailure(e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(ForbiddenFailure(e.message));
    } on ValidationException catch (e) {
      return FailureResult(ValidationFailure(message: e.message, fieldErrors: e.errors));
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message, statusCode: e.statusCode));
    } on ApiException catch (e) {
      return FailureResult(ServerFailure(e.message));
    }
  }

  @override
  Future<Result<GradeRecap>> fetchGradeRecap(int taId) async {
    try {
      final data = await _remote.fetchGradeRecap(taId);
      return Success(data);
    } on NetworkException catch (e) {
      return FailureResult(NetworkFailure(e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(AuthFailure(e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(ForbiddenFailure(e.message));
    } on ValidationException catch (e) {
      return FailureResult(ValidationFailure(message: e.message, fieldErrors: e.errors));
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message, statusCode: e.statusCode));
    } on ApiException catch (e) {
      return FailureResult(ServerFailure(e.message));
    }
  }
}
