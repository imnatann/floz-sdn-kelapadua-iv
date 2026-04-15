import 'package:dio/dio.dart';
import '../../../../../core/network/api_client.dart';

class AssignmentApi {
  final ApiClient _apiClient;

  AssignmentApi(this._apiClient);

  Future<List<dynamic>> getAssignments({String status = 'upcoming'}) async {
    try {
      final response = await _apiClient.dio.get(
        '/assignments',
        queryParameters: {'status': status},
      );
      return response.data['data'] as List<dynamic>;
    } on DioException catch (e) {
      final message = e.response?.data?['message'];
      if (message != null) throw Exception(message);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getAssignmentDetail(int id) async {
    try {
      final response = await _apiClient.dio.get('/assignments/$id');
      return response.data['assignment'] as Map<String, dynamic>;
    } on DioException catch (e) {
      final message = e.response?.data?['message'];
      if (message != null) throw Exception(message);
      rethrow;
    }
  }
}
