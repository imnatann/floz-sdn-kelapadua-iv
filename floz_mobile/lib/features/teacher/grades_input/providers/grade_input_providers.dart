import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/result.dart';
import '../../../auth/providers/auth_providers.dart';
import '../data/datasources/grade_input_remote_datasource.dart';
import '../data/repositories/grade_input_repository_impl.dart';
import '../domain/entities/grade_roster.dart';
import '../domain/repositories/grade_input_repository.dart';

final gradeInputRemoteProvider = Provider<GradeInputRemoteDataSource>((ref) {
  return GradeInputRemoteDataSourceImpl(ref.watch(apiClientProvider));
});

final gradeInputRepositoryProvider = Provider<GradeInputRepository>((ref) {
  return GradeInputRepositoryImpl(remote: ref.watch(gradeInputRemoteProvider));
});

final gradeRosterProvider =
    FutureProvider.family<GradeRoster, int>((ref, taId) async {
  final result = await ref.read(gradeInputRepositoryProvider).fetchRoster(taId);
  switch (result) {
    case Success(:final data):
      return data;
    case FailureResult(:final failure):
      throw failure;
  }
});

class GradeSubmitController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> submit({
    required int taId,
    required List<Map<String, dynamic>> entries,
  }) async {
    state = const AsyncLoading();
    final result = await ref
        .read(gradeInputRepositoryProvider)
        .submitGrades(taId, entries);
    switch (result) {
      case Success():
        ref.invalidate(gradeRosterProvider(taId));
        state = const AsyncData(null);
        return true;
      case FailureResult(:final failure):
        state = AsyncError(failure, StackTrace.current);
        return false;
    }
  }
}

final gradeSubmitControllerProvider =
    AsyncNotifierProvider<GradeSubmitController, void>(
        GradeSubmitController.new);
