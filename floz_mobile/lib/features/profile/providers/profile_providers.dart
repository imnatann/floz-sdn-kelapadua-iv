import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_session.dart';
import '../../../core/error/result.dart';
import '../../auth/providers/auth_providers.dart';

class LogoutController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> submit() async {
    state = const AsyncLoading();
    final result = await ref.read(authRepositoryProvider).logout();
    return switch (result) {
      Success() => () {
          ref.read(authSessionProvider.notifier).clear();
          state = const AsyncData(null);
          return true;
        }(),
      FailureResult(:final failure) => () {
          // Backend logout failed but we still want to clear local session
          // (token is already cleared from storage by repo on any error).
          ref.read(authSessionProvider.notifier).clear();
          state = AsyncError(failure, StackTrace.current);
          return true;
        }(),
    };
  }
}

final logoutControllerProvider =
    AsyncNotifierProvider<LogoutController, void>(LogoutController.new);
