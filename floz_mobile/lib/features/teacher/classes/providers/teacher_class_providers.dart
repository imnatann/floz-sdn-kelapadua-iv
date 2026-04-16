import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/result.dart';
import '../../../../core/storage/cache_box.dart';
import '../../../auth/providers/auth_providers.dart';
import '../data/datasources/teacher_class_remote_data_source.dart';
import '../data/repositories/teacher_class_repository_impl.dart';
import '../domain/entities/class_meetings.dart';
import '../domain/entities/teaching_assignment_summary.dart';
import '../domain/repositories/teacher_class_repository.dart';

final teacherClassCacheProvider = Provider<CacheBox<dynamic>>((ref) {
  return CacheBox<dynamic>(name: 'teacher_class_cache', ttl: const Duration(hours: 1));
});

final teacherClassRemoteProvider = Provider<TeacherClassRemoteDataSource>((ref) {
  return TeacherClassRemoteDataSourceImpl(ref.watch(apiClientProvider));
});

final teacherClassRepositoryProvider = Provider<TeacherClassRepository>((ref) {
  return TeacherClassRepositoryImpl(
    remote: ref.watch(teacherClassRemoteProvider),
    cache: ref.watch(teacherClassCacheProvider),
  );
});

class TeacherClassListNotifier
    extends AsyncNotifier<List<TeachingAssignmentSummary>> {
  @override
  Future<List<TeachingAssignmentSummary>> build() async {
    final result = await ref.read(teacherClassRepositoryProvider).fetchList();
    switch (result) {
      case Success(:final data):
        return data;
      case FailureResult(:final failure):
        throw failure;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final result = await ref.read(teacherClassRepositoryProvider).fetchList();
    state = await AsyncValue.guard(() async {
      switch (result) {
        case Success(:final data):
          return data;
        case FailureResult(:final failure):
          throw failure;
      }
    });
  }
}

final teacherClassListNotifierProvider =
    AsyncNotifierProvider<TeacherClassListNotifier, List<TeachingAssignmentSummary>>(
        TeacherClassListNotifier.new);

final teacherMeetingsProvider =
    FutureProvider.family<ClassMeetings, int>((ref, taId) async {
  final result =
      await ref.read(teacherClassRepositoryProvider).fetchMeetings(taId);
  switch (result) {
    case Success(:final data):
      return data;
    case FailureResult(:final failure):
      throw failure;
  }
});
