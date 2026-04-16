import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/result.dart';
import '../../../../core/storage/cache_box.dart';
import '../../../auth/providers/auth_providers.dart';
import '../data/datasources/grade_remote_datasource.dart';
import '../data/repositories/grade_repository_impl.dart';
import '../domain/entities/student_grades.dart';
import '../domain/repositories/grade_repository.dart';

final gradeCacheProvider = Provider<CacheBox<dynamic>>((ref) {
  return CacheBox<dynamic>(name: 'grade_cache', ttl: const Duration(hours: 1));
});

final gradeRemoteProvider = Provider<GradeRemoteDataSource>((ref) {
  return GradeRemoteDataSourceImpl(ref.watch(apiClientProvider));
});

final gradeRepositoryProvider = Provider<GradeRepository>((ref) {
  return GradeRepositoryImpl(
    remote: ref.watch(gradeRemoteProvider),
    cache: ref.watch(gradeCacheProvider),
  );
});

class GradeListNotifier extends AsyncNotifier<List<SubjectGradeSummary>> {
  @override
  Future<List<SubjectGradeSummary>> build() async {
    final result = await ref.read(gradeRepositoryProvider).fetchList();
    switch (result) {
      case Success(:final data):
        return data;
      case FailureResult(:final failure):
        throw failure;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final result = await ref.read(gradeRepositoryProvider).fetchList(forceRefresh: true);
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

final gradeListNotifierProvider =
    AsyncNotifierProvider<GradeListNotifier, List<SubjectGradeSummary>>(GradeListNotifier.new);

final gradeDetailProvider = FutureProvider.family<SubjectGradeInfo, int>((ref, subjectId) async {
  final result = await ref.read(gradeRepositoryProvider).fetchDetail(subjectId);
  switch (result) {
    case Success(:final data):
      return data;
    case FailureResult(:final failure):
      throw failure;
  }
});
