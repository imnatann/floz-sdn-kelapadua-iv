import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/result.dart';
import '../../../../core/storage/cache_box.dart';
import '../../../auth/providers/auth_providers.dart';
import '../data/datasources/report_card_remote_datasource.dart';
import '../data/repositories/report_card_repository_impl.dart';
import '../domain/entities/report_card.dart';
import '../domain/repositories/report_card_repository.dart';

final reportCardCacheProvider = Provider<CacheBox<dynamic>>((ref) {
  return CacheBox<dynamic>(name: 'report_card_cache', ttl: const Duration(days: 1));
});

final reportCardRemoteProvider = Provider<ReportCardRemoteDataSource>((ref) {
  return ReportCardRemoteDataSourceImpl(ref.watch(apiClientProvider));
});

final reportCardRepositoryProvider = Provider<ReportCardRepository>((ref) {
  return ReportCardRepositoryImpl(
    remote: ref.watch(reportCardRemoteProvider),
    cache: ref.watch(reportCardCacheProvider),
  );
});

class ReportCardListNotifier extends AsyncNotifier<List<ReportCardSummary>> {
  @override
  Future<List<ReportCardSummary>> build() async {
    final result = await ref.read(reportCardRepositoryProvider).fetchList();
    switch (result) {
      case Success(:final data):
        return data;
      case FailureResult(:final failure):
        throw failure;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final result = await ref.read(reportCardRepositoryProvider).fetchList(forceRefresh: true);
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

final reportCardListNotifierProvider =
    AsyncNotifierProvider<ReportCardListNotifier, List<ReportCardSummary>>(
        ReportCardListNotifier.new);

final reportCardDetailProvider =
    FutureProvider.family<ReportCardDetail, int>((ref, id) async {
  final result = await ref.read(reportCardRepositoryProvider).fetchDetail(id);
  switch (result) {
    case Success(:final data):
      return data;
    case FailureResult(:final failure):
      throw failure;
  }
});
