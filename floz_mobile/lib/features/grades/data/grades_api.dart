import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

class GradesApi {
  final ApiClient _apiClient;

  GradesApi(this._apiClient);

  Future<List<dynamic>> getGradesSummary() async {
    try {
      final response = await _apiClient.dio.get('/grades');
      return response.data['grades'] as List<dynamic>;
    } on DioException catch (e) {
      final message = e.response?.data?['message'];
      if (message != null) {
        throw Exception(message);
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> subjectGradeDetail(int subjectId) async {
    try {
      final response = await _apiClient.dio.get('/grades/$subjectId');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final message = e.response?.data?['message'];
      if (message != null) {
        throw Exception(message);
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }
}
