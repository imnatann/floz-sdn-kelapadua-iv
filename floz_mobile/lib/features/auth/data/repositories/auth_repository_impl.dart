import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/storage/secure_token_storage.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;
  final TokenStorage _tokenStorage;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required TokenStorage tokenStorage,
  })  : _remote = remote,
        _tokenStorage = tokenStorage;

  @override
  Future<Result<({User user, String token})>> login({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _remote.login(email: email, password: password);
      await _tokenStorage.write(result.token);
      return Success(result);
    } on UnauthorizedException catch (e) {
      return FailureResult(AuthFailure(e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(ForbiddenFailure(e.message));
    } on ValidationException catch (e) {
      return FailureResult(ValidationFailure(message: e.message, fieldErrors: e.errors));
    } on NetworkException catch (e) {
      return FailureResult(NetworkFailure(e.message));
    } on RateLimitException catch (e) {
      return FailureResult(ServerFailure(e.message, statusCode: 429));
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await _remote.logout();
      await _tokenStorage.clear();
      return const Success(null);
    } on ApiException catch (e) {
      await _tokenStorage.clear();
      return FailureResult(ServerFailure(e.message));
    }
  }

  @override
  Future<Result<User>> me() async {
    try {
      final user = await _remote.me();
      return Success(user);
    } on UnauthorizedException catch (e) {
      await _tokenStorage.clear();
      return FailureResult(AuthFailure(e.message));
    } on NetworkException catch (e) {
      return FailureResult(NetworkFailure(e.message));
    } on ApiException catch (e) {
      return FailureResult(ServerFailure(e.message));
    }
  }
}
