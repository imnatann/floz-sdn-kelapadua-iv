import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/dashboard_api.dart';
import '../data/dashboard_repository.dart';
import '../domain/dashboard_models.dart';

final dashboardApiProvider = Provider((ref) {
  final client = ref.watch(apiClientProvider);
  return DashboardApi(client);
});

final dashboardRepositoryProvider = Provider((ref) {
  final api = ref.watch(dashboardApiProvider);
  return DashboardRepository(api);
});

final dashboardProvider = FutureProvider.autoDispose<StudentDashboardData>((
  ref,
) async {
  final repo = ref.watch(dashboardRepositoryProvider);
  return repo.getStudentDashboard();
});
