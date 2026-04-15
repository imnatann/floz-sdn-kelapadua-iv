import '../../../../core/network/api_client.dart';

class DashboardApi {
  final ApiClient _apiClient;

  DashboardApi(this._apiClient);

  Future<Map<String, dynamic>> fetchDashboardData() async {
    try {
      final response = await _apiClient.dio.get('/dashboard');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}
