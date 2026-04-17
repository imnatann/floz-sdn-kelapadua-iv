import '../../../../../core/error/failure.dart';
import '../../../../../core/error/result.dart';
import '../../../../../core/network/api_exception.dart';
import '../../domain/entities/notifications_page.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_remote_datasource.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  final NotificationsRemoteDataSource _remote;

  NotificationsRepositoryImpl({required NotificationsRemoteDataSource remote})
      : _remote = remote;

  @override
  Future<Result<NotificationsPage>> fetch() => _guard(() => _remote.fetch());

  @override
  Future<Result<void>> markAsRead(String id) =>
      _guard(() => _remote.markAsRead(id));

  @override
  Future<Result<int>> markAllAsRead() => _guard(() => _remote.markAllAsRead());

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
