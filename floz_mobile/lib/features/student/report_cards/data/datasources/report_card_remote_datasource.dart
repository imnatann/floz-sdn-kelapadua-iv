import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_endpoints.dart';
import '../../domain/entities/report_card.dart';
import '../models/report_card_dto.dart';

abstract class ReportCardRemoteDataSource {
  Future<List<ReportCardSummary>> fetchList();
  Future<ReportCardDetail> fetchDetail(int id);
  Future<String?> fetchPdfUrl(int id);
}

class ReportCardRemoteDataSourceImpl implements ReportCardRemoteDataSource {
  final ApiClient _client;
  ReportCardRemoteDataSourceImpl(this._client);

  @override
  Future<List<ReportCardSummary>> fetchList() async {
    final res = await _client.get(ApiEndpoints.studentReportCards);
    final body = res.data as Map<String, dynamic>;
    return ReportCardDto.listFromJson(body['data'] as List? ?? []);
  }

  @override
  Future<ReportCardDetail> fetchDetail(int id) async {
    final res = await _client.get('${ApiEndpoints.studentReportCards}/$id');
    final body = res.data as Map<String, dynamic>;
    return ReportCardDto.detailFromJson(body['data'] as Map<String, dynamic>? ?? {});
  }

  @override
  Future<String?> fetchPdfUrl(int id) async {
    final res = await _client.get('${ApiEndpoints.studentReportCards}/$id/pdf');
    final body = res.data as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>? ?? {};
    return data['url'] as String?;
  }
}
