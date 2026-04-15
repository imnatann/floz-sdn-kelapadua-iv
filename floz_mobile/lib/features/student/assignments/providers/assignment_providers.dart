import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/providers/auth_provider.dart';
import '../data/assignment_api.dart';
import '../data/assignment_repository.dart';
import '../domain/assignment_models.dart';

final assignmentApiProvider = Provider<AssignmentApi>((ref) {
  final client = ref.watch(apiClientProvider);
  return AssignmentApi(client);
});

final assignmentRepositoryProvider = Provider<AssignmentRepository>((ref) {
  final api = ref.watch(assignmentApiProvider);
  return AssignmentRepository(api);
});

// A provider for upcoming assignments
final upcomingAssignmentsProvider =
    FutureProvider.autoDispose<List<AssignmentItem>>((ref) async {
      final repo = ref.watch(assignmentRepositoryProvider);
      return repo.getAssignments(status: 'upcoming');
    });

// A provider for completed assignments
final completedAssignmentsProvider =
    FutureProvider.autoDispose<List<AssignmentItem>>((ref) async {
      final repo = ref.watch(assignmentRepositoryProvider);
      return repo.getAssignments(status: 'completed');
    });

// A family provider for assignment details
final assignmentDetailProvider = FutureProvider.autoDispose
    .family<AssignmentDetail, int>((ref, id) async {
      final repo = ref.watch(assignmentRepositoryProvider);
      return repo.getAssignmentDetail(id);
    });
