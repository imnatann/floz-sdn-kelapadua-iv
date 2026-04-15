import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/grades_api.dart';
import '../data/grades_repository.dart';
import '../domain/grades_models.dart';

final gradesApiProvider = Provider<GradesApi>((ref) {
  final client = ref.watch(apiClientProvider);
  return GradesApi(client);
});

final gradesRepositoryProvider = Provider<GradesRepository>((ref) {
  final api = ref.watch(gradesApiProvider);
  return GradesRepository(api);
});

final gradesSummaryProvider =
    FutureProvider.autoDispose<List<SubjectGradeSummary>>((ref) async {
      final repo = ref.watch(gradesRepositoryProvider);
      return repo.getGradesSummary();
    });

final gradeDetailProvider = FutureProvider.autoDispose
    .family<SubjectGradeDetailResponse, int>((ref, subjectId) async {
      final repo = ref.watch(gradesRepositoryProvider);
      return repo.getGradeDetail(subjectId);
    });
