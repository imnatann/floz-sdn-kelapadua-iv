import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/result.dart';
import '../../../../core/storage/cache_box.dart';
import '../../../auth/providers/auth_providers.dart';
import '../data/datasources/assignment_remote_datasource.dart';
import '../data/repositories/assignment_repository_impl.dart';
import '../domain/entities/assignment.dart';
import '../domain/repositories/assignment_repository.dart';

final assignmentCacheProvider = Provider<CacheBox<dynamic>>((ref) {
  return CacheBox<dynamic>(
    name: 'assignment_cache',
    ttl: const Duration(minutes: 30),
  );
});

final assignmentRemoteProvider = Provider<AssignmentRemoteDataSource>((ref) {
  return AssignmentRemoteDataSourceImpl(ref.watch(apiClientProvider));
});

final assignmentRepositoryProvider = Provider<AssignmentRepository>((ref) {
  return AssignmentRepositoryImpl(
    remote: ref.watch(assignmentRemoteProvider),
    cache: ref.watch(assignmentCacheProvider),
  );
});

class AssignmentListNotifier extends AsyncNotifier<List<AssignmentSummary>> {
  String _status = 'upcoming';

  @override
  Future<List<AssignmentSummary>> build() async {
    return _fetch();
  }

  Future<List<AssignmentSummary>> _fetch({bool forceRefresh = false}) async {
    final result = await ref
        .read(assignmentRepositoryProvider)
        .fetchList(status: _status, forceRefresh: forceRefresh);
    switch (result) {
      case Success(:final data):
        return data;
      case FailureResult(:final failure):
        throw failure;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(forceRefresh: true));
  }

  Future<void> switchFilter(String status) async {
    if (_status == status) return;
    _status = status;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch());
  }
}

final assignmentListNotifierProvider =
    AsyncNotifierProvider<AssignmentListNotifier, List<AssignmentSummary>>(
        AssignmentListNotifier.new);

final assignmentDetailProvider =
    FutureProvider.family<AssignmentDetail, int>((ref, id) async {
  final result =
      await ref.read(assignmentRepositoryProvider).fetchDetail(id);
  switch (result) {
    case Success(:final data):
      return data;
    case FailureResult(:final failure):
      throw failure;
  }
});
