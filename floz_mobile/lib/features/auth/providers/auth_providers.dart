import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_token_storage.dart';
import '../../../core/auth/auth_session.dart';
import '../../../core/error/result.dart';
import '../data/datasources/auth_remote_datasource.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../domain/repositories/auth_repository.dart';

const _baseUrl = String.fromEnvironment(
  'FLOZ_API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000/api/v1',
);

final tokenStorageProvider = Provider<TokenStorage>((ref) => SecureTokenStorage());

final apiClientProvider = Provider<ApiClient>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  return ApiClient(
    baseUrl: _baseUrl,
    tokenStorage: tokenStorage,
    onUnauthorized: () => ref.read(authSessionProvider.notifier).clear(),
  );
});

final authRemoteProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(ref.watch(apiClientProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remote: ref.watch(authRemoteProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

class LoginController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> submit({required String email, required String password}) async {
    state = const AsyncLoading();
    final result = await ref.read(authRepositoryProvider).login(
          email: email,
          password: password,
        );
    return switch (result) {
      Success(:final data) => () {
          ref.read(authSessionProvider.notifier).setSession(data.user, data.token);
          state = const AsyncData(null);
          return true;
        }(),
      FailureResult(:final failure) => () {
          state = AsyncError(failure, StackTrace.current);
          return false;
        }(),
    };
  }
}

final loginControllerProvider =
    AsyncNotifierProvider<LoginController, void>(LoginController.new);
