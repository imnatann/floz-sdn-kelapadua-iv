import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/result.dart';
import '../../../../core/storage/cache_box.dart';
import '../../../auth/providers/auth_providers.dart';
import '../data/datasources/dashboard_remote_datasource.dart';
import '../data/repositories/dashboard_repository_impl.dart';
import '../domain/entities/dashboard.dart';
import '../domain/repositories/dashboard_repository.dart';

final dashboardCacheProvider = Provider<CacheBox<dynamic>>((ref) {
  return CacheBox<dynamic>(name: 'dashboard_cache', ttl: const Duration(minutes: 5));
});

final dashboardRemoteProvider = Provider<DashboardRemoteDataSource>((ref) {
  return DashboardRemoteDataSourceImpl(ref.watch(apiClientProvider));
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(
    remote: ref.watch(dashboardRemoteProvider),
    cache: ref.watch(dashboardCacheProvider),
  );
});

class DashboardNotifier extends AsyncNotifier<StudentDashboard> {
  @override
  Future<StudentDashboard> build() async {
    final result = await ref.read(dashboardRepositoryProvider).fetch();
    return _throwOrReturn(result);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final result = await ref.read(dashboardRepositoryProvider).fetch(forceRefresh: true);
    state = await AsyncValue.guard(() async => _throwOrReturn(result));
  }

  StudentDashboard _throwOrReturn(Result<StudentDashboard> result) {
    switch (result) {
      case Success(:final data):
        return data;
      case FailureResult(:final failure):
        throw failure;
    }
  }
}

final dashboardNotifierProvider =
    AsyncNotifierProvider<DashboardNotifier, StudentDashboard>(DashboardNotifier.new);
