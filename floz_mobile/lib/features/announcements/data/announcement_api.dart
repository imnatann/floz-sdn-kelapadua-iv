import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

class AnnouncementApi {
  final ApiClient _apiClient;

  AnnouncementApi(this._apiClient);

  Future<List<dynamic>> getAnnouncements() async {
    try {
      final response = await _apiClient.dio.get('/announcements');
      return response.data['data'] as List<dynamic>;
    } on DioException catch (e) {
      final message = e.response?.data?['message'];
      if (message != null) throw Exception(message);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getAnnouncementDetail(int id) async {
    try {
      final response = await _apiClient.dio.get('/announcements/$id');
      return response.data['announcement'] as Map<String, dynamic>;
    } on DioException catch (e) {
      final message = e.response?.data?['message'];
      if (message != null) throw Exception(message);
      rethrow;
    }
  }
}
