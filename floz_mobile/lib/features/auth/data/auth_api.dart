import 'package:dio/dio.dart';
import '../domain/user_model.dart';
import '../../../../core/network/api_client.dart';

class AuthApi {
  final ApiClient _apiClient;

  AuthApi(this._apiClient);

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      return response.data;
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

  Future<void> logout() async {
    try {
      await _apiClient.dio.post('/auth/logout');
    } catch (e) {
      // Ignore logout errors
    }
  }

  Future<User> getMe() async {
    try {
      final response = await _apiClient.dio.get('/auth/me');
      return User.fromJson(response.data['user']);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> searchTenants(String query) async {
    try {
      final response = await _apiClient.dio.get(
        '/tenants/search',
        queryParameters: {'q': query},
      );
      final List<dynamic> data = response.data;
      return data.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      return [];
    }
  }
}
