import '../../../../../core/network/api_client.dart';

class ScheduleApi {
  final ApiClient _apiClient;

  ScheduleApi(this._apiClient);

  Future<List<dynamic>> fetchWeeklySchedule() async {
    try {
      final response = await _apiClient.dio.get('/schedules');
      return response.data['schedules'] ?? [];
    } catch (e) {
      rethrow;
    }
  }
}
