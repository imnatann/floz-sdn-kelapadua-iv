import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/providers/auth_provider.dart';
import '../data/schedule_api.dart';
import '../data/schedule_repository.dart';
import '../domain/schedule_models.dart';

final scheduleApiProvider = Provider((ref) {
  final client = ref.watch(apiClientProvider);
  return ScheduleApi(client);
});

final scheduleRepositoryProvider = Provider((ref) {
  final api = ref.watch(scheduleApiProvider);
  return ScheduleRepository(api);
});

final scheduleProvider = FutureProvider.autoDispose<List<WeeklySchedule>>((
  ref,
) async {
  final repo = ref.watch(scheduleRepositoryProvider);
  return repo.getWeeklySchedule();
});
