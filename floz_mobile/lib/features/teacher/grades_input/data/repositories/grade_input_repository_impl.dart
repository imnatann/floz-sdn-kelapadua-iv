import '../../../../../core/error/failure.dart';
import '../../../../../core/error/result.dart';
import '../../../../../core/network/api_exception.dart';
import '../../domain/entities/grade_roster.dart';
import '../../domain/repositories/grade_input_repository.dart';
import '../datasources/grade_input_remote_datasource.dart';

class GradeInputRepositoryImpl implements GradeInputRepository {
  final GradeInputRemoteDataSource _remote;

  GradeInputRepositoryImpl({required GradeInputRemoteDataSource remote})
      : _remote = remote;

  @override
  Future<Result<GradeRoster>> fetchRoster(int taId) async {
    try {
      final data = await _remote.fetchRoster(taId);
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
  Future<Result<GradeRoster>> submitGrades(
    int taId,
    List<Map<String, dynamic>> entries,
  ) async {
    try {
      final data = await _remote.submitGrades(taId, entries);
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
