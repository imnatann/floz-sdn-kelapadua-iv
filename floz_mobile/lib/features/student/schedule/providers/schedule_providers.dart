import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/result.dart';
import '../../../../core/storage/cache_box.dart';
import '../../../auth/providers/auth_providers.dart';
import '../data/datasources/schedule_remote_datasource.dart';
import '../data/repositories/schedule_repository_impl.dart';
import '../domain/entities/weekly_schedule.dart';
import '../domain/repositories/schedule_repository.dart';

final scheduleCacheProvider = Provider<CacheBox<dynamic>>((ref) {
  return CacheBox<dynamic>(name: 'schedule_cache', ttl: const Duration(hours: 24));
});

final scheduleRemoteProvider = Provider<ScheduleRemoteDataSource>((ref) {
  return ScheduleRemoteDataSourceImpl(ref.watch(apiClientProvider));
});

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  return ScheduleRepositoryImpl(
    remote: ref.watch(scheduleRemoteProvider),
    cache: ref.watch(scheduleCacheProvider),
  );
});

class ScheduleNotifier extends AsyncNotifier<WeeklySchedule> {
  @override
  Future<WeeklySchedule> build() async {
    final result = await ref.read(scheduleRepositoryProvider).fetch();
    return _throwOrReturn(result);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final result = await ref
        .read(scheduleRepositoryProvider)
        .fetch(forceRefresh: true);
    state = await AsyncValue.guard(() async => _throwOrReturn(result));
  }

  WeeklySchedule _throwOrReturn(Result<WeeklySchedule> result) {
    switch (result) {
      case Success(:final data):
        return data;
      case FailureResult(:final failure):
        throw failure;
    }
  }
}

final scheduleNotifierProvider =
    AsyncNotifierProvider<ScheduleNotifier, WeeklySchedule>(ScheduleNotifier.new);
