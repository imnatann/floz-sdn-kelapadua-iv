import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/result.dart';
import '../../../auth/providers/auth_providers.dart';
import '../data/datasources/notifications_remote_datasource.dart';
import '../data/repositories/notifications_repository_impl.dart';
import '../domain/entities/notifications_page.dart';
import '../domain/repositories/notifications_repository.dart';

final notificationsRemoteProvider = Provider<NotificationsRemoteDataSource>((ref) {
  return NotificationsRemoteDataSourceImpl(ref.watch(apiClientProvider));
});

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepositoryImpl(remote: ref.watch(notificationsRemoteProvider));
});

final notificationsPageProvider = FutureProvider<NotificationsPage>((ref) async {
  final repo = ref.watch(notificationsRepositoryProvider);
  final result = await repo.fetch();
  return switch (result) {
    Success(:final data) => data,
    FailureResult(:final failure) => throw failure,
  };
});

/// Convenience provider: unread count for the bell badge.
/// Returns 0 while loading or on error — bell stays clean rather than showing stale.
final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsPageProvider).maybeWhen(
        data: (page) => page.unreadCount,
        orElse: () => 0,
      );
});
