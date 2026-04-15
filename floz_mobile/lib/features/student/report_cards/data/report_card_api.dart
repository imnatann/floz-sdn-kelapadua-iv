import 'package:dio/dio.dart';
import '../../../../../core/network/api_client.dart';

class ReportCardApi {
  final ApiClient _apiClient;

  ReportCardApi(this._apiClient);

  Future<List<dynamic>> getReportCards() async {
    try {
      final response = await _apiClient.dio.get('/report-cards');
      return response.data['report_cards'] as List<dynamic>;
    } on DioException catch (e) {
      final message = e.response?.data?['message'];
      if (message != null) throw Exception(message);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getReportCardDetail(int id) async {
    try {
      final response = await _apiClient.dio.get('/report-cards/$id');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final message = e.response?.data?['message'];
      if (message != null) throw Exception(message);
      rethrow;
    }
  }

  Future<String> getPdfUrl(int id) async {
    try {
      final response = await _apiClient.dio.get('/report-cards/$id/pdf');
      return response.data['url'] as String;
    } on DioException catch (e) {
      final message = e.response?.data?['message'];
      if (message != null) throw Exception(message);
      rethrow;
    }
  }
}
