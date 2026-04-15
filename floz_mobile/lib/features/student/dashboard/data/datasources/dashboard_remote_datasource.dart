import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_endpoints.dart';
import '../../domain/entities/dashboard.dart';
import '../models/dashboard_dto.dart';

abstract class DashboardRemoteDataSource {
  Future<StudentDashboard> fetch();
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final ApiClient _client;

  DashboardRemoteDataSourceImpl(this._client);

  @override
  Future<StudentDashboard> fetch() async {
    final res = await _client.get(ApiEndpoints.studentDashboard);
    final body = res.data as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>;
    return DashboardDto.fromJson(data);
  }
}
