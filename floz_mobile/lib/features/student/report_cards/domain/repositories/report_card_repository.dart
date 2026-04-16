import '../../../../../core/error/result.dart';
import '../entities/report_card.dart';

abstract class ReportCardRepository {
  Future<Result<List<ReportCardSummary>>> fetchList({bool forceRefresh = false});
  Future<Result<ReportCardDetail>> fetchDetail(int id);
  Future<Result<String>> fetchPdfUrl(int id);
}
