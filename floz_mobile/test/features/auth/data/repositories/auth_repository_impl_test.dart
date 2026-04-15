import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:floz_mobile/core/error/failure.dart';
import 'package:floz_mobile/core/error/result.dart';
import 'package:floz_mobile/core/network/api_exception.dart';
import 'package:floz_mobile/core/storage/secure_token_storage.dart';
import 'package:floz_mobile/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:floz_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:floz_mobile/features/auth/domain/entities/user.dart';

class _MockRemote extends Mock implements AuthRemoteDataSource {}
class _MockTokenStorage extends Mock implements TokenStorage {}

void main() {
  late _MockRemote remote;
  late _MockTokenStorage tokenStorage;
  late AuthRepositoryImpl repo;

  setUp(() {
    remote = _MockRemote();
    tokenStorage = _MockTokenStorage();
    repo = AuthRepositoryImpl(remote: remote, tokenStorage: tokenStorage);
  });

  group('login', () {
    test('returns Success and persists token on happy path', () async {
      const user = User(
        id: 1, name: 'Ahmad', email: 'a@b.co', role: 'student', isActive: true,
      );
      when(() => remote.login(email: any(named: 'email'), password: any(named: 'password')))
          .thenAnswer((_) async => (user: user, token: 'tok-123'));
      when(() => tokenStorage.write(any())).thenAnswer((_) async {});

      final result = await repo.login(email: 'a@b.co', password: 'rahasia');

      expect(result, isA<Success>());
      verify(() => tokenStorage.write('tok-123')).called(1);
    });

    test('returns AuthFailure on 401', () async {
      when(() => remote.login(email: any(named: 'email'), password: any(named: 'password')))
          .thenThrow(const UnauthorizedException('wrong'));

      final result = await repo.login(email: 'a@b.co', password: 'wrong1');

      expect(result, isA<FailureResult>());
      expect((result as FailureResult).failure, isA<AuthFailure>());
    });

    test('returns ValidationFailure on 422 with field errors', () async {
      when(() => remote.login(email: any(named: 'email'), password: any(named: 'password')))
          .thenThrow(const ValidationException('invalid', {'email': ['required']}));

      final result = await repo.login(email: '', password: '');

      final failureResult = result as FailureResult;
      expect(failureResult.failure, isA<ValidationFailure>());
      expect((failureResult.failure as ValidationFailure).fieldErrors['email'], ['required']);
    });

    test('returns NetworkFailure on offline', () async {
      when(() => remote.login(email: any(named: 'email'), password: any(named: 'password')))
          .thenThrow(const NetworkException('offline'));

      final result = await repo.login(email: 'a@b.co', password: 'x1234');

      expect((result as FailureResult).failure, isA<NetworkFailure>());
    });
  });

  group('logout', () {
    test('clears token even on server failure', () async {
      when(() => remote.logout()).thenThrow(const ServerException('boom'));
      when(() => tokenStorage.clear()).thenAnswer((_) async {});

      final result = await repo.logout();

      verify(() => tokenStorage.clear()).called(1);
      expect(result, isA<FailureResult>());
    });
  });

  group('me', () {
    test('returns Success(user) on happy path', () async {
      const user = User(
        id: 1, name: 'A', email: 'a@b.co', role: 'student', isActive: true,
      );
      when(() => remote.me()).thenAnswer((_) async => user);
      final result = await repo.me();
      expect(result, isA<Success<User>>());
    });

    test('clears token and returns AuthFailure on 401', () async {
      when(() => remote.me()).thenThrow(const UnauthorizedException('expired'));
      when(() => tokenStorage.clear()).thenAnswer((_) async {});
      final result = await repo.me();
      verify(() => tokenStorage.clear()).called(1);
      expect((result as FailureResult).failure, isA<AuthFailure>());
    });
  });
}
