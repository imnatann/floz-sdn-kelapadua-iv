import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/result.dart';
import '../../../../core/storage/cache_box.dart';
import '../../../auth/providers/auth_providers.dart';
import '../data/datasources/announcement_remote_datasource.dart';
import '../data/repositories/announcement_repository_impl.dart';
import '../domain/entities/announcement.dart';
import '../domain/repositories/announcement_repository.dart';

final announcementCacheProvider = Provider<CacheBox<dynamic>>((ref) {
  return CacheBox<dynamic>(name: 'announcement_cache', ttl: const Duration(minutes: 30));
});

final announcementRemoteProvider = Provider<AnnouncementRemoteDataSource>((ref) {
  return AnnouncementRemoteDataSourceImpl(ref.watch(apiClientProvider));
});

final announcementRepositoryProvider = Provider<AnnouncementRepository>((ref) {
  return AnnouncementRepositoryImpl(
    remote: ref.watch(announcementRemoteProvider),
    cache: ref.watch(announcementCacheProvider),
  );
});

class AnnouncementListNotifier extends AsyncNotifier<List<AnnouncementSummary>> {
  @override
  Future<List<AnnouncementSummary>> build() async {
    final result = await ref.read(announcementRepositoryProvider).fetchList();
    switch (result) {
      case Success(:final data):
        return data;
      case FailureResult(:final failure):
        throw failure;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final result = await ref.read(announcementRepositoryProvider).fetchList(forceRefresh: true);
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

final announcementListNotifierProvider =
    AsyncNotifierProvider<AnnouncementListNotifier, List<AnnouncementSummary>>(
        AnnouncementListNotifier.new);

final announcementDetailProvider = FutureProvider.family<AnnouncementDetail, int>((ref, id) async {
  final result = await ref.read(announcementRepositoryProvider).fetchDetail(id);
  switch (result) {
    case Success(:final data):
      return data;
    case FailureResult(:final failure):
      throw failure;
  }
});
