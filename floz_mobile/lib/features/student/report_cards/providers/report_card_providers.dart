import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/providers/auth_provider.dart';
import '../data/report_card_api.dart';
import '../data/report_card_repository.dart';
import '../domain/report_card_models.dart';

final reportCardApiProvider = Provider<ReportCardApi>((ref) {
  final client = ref.watch(apiClientProvider);
  return ReportCardApi(client);
});

final reportCardRepositoryProvider = Provider<ReportCardRepository>((ref) {
  final api = ref.watch(reportCardApiProvider);
  return ReportCardRepository(api);
});

final reportCardsProvider = FutureProvider.autoDispose<List<ReportCardSummary>>(
  (ref) async {
    final repo = ref.watch(reportCardRepositoryProvider);
    return repo.getReportCards();
  },
);

final reportCardDetailProvider = FutureProvider.autoDispose
    .family<ReportCardDetail, int>((ref, id) async {
      final repo = ref.watch(reportCardRepositoryProvider);
      return repo.getReportCardDetail(id);
    });
