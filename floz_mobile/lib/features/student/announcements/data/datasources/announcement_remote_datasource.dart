import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_endpoints.dart';
import '../../domain/entities/announcement.dart';
import '../models/announcement_dto.dart';

abstract class AnnouncementRemoteDataSource {
  Future<List<AnnouncementSummary>> fetchList();
  Future<AnnouncementDetail> fetchDetail(int id);
}

class AnnouncementRemoteDataSourceImpl implements AnnouncementRemoteDataSource {
  final ApiClient _client;
  AnnouncementRemoteDataSourceImpl(this._client);

  @override
  Future<List<AnnouncementSummary>> fetchList() async {
    final res = await _client.get(ApiEndpoints.studentAnnouncements);
    final body = res.data as Map<String, dynamic>;
    final data = body['data'] as List? ?? const [];
    return AnnouncementDto.listFromJson(data);
  }

  @override
  Future<AnnouncementDetail> fetchDetail(int id) async {
    final res = await _client.get('${ApiEndpoints.studentAnnouncements}/$id');
    final body = res.data as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>? ?? {};
    return AnnouncementDto.detailFromJson(data);
  }
}
