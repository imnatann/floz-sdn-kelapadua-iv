import '../domain/report_card_models.dart';
import 'report_card_api.dart';

class ReportCardRepository {
  final ReportCardApi _api;

  ReportCardRepository(this._api);

  Future<List<ReportCardSummary>> getReportCards() async {
    final data = await _api.getReportCards();
    return data.map((e) => ReportCardSummary.fromJson(e)).toList();
  }

  Future<ReportCardDetail> getReportCardDetail(int id) async {
    final data = await _api.getReportCardDetail(id);
    return ReportCardDetail.fromJson(data);
  }

  Future<String> getPdfUrl(int id) async {
    return await _api.getPdfUrl(id);
  }
}
