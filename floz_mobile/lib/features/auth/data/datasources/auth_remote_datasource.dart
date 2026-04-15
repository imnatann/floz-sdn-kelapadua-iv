import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/user.dart';
import '../models/user_dto.dart';

abstract class AuthRemoteDataSource {
  Future<({User user, String token})> login({
    required String email,
    required String password,
  });

  Future<void> logout();

  Future<User> me();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _client;

  AuthRemoteDataSourceImpl(this._client);

  @override
  Future<({User user, String token})> login({
    required String email,
    required String password,
  }) async {
    final res = await _client.post(
      ApiEndpoints.authLogin,
      body: {'email': email, 'password': password},
    );
    final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    final user = UserDto.fromJson(data['user'] as Map<String, dynamic>);
    final token = data['token'] as String;
    return (user: user, token: token);
  }

  @override
  Future<void> logout() async {
    await _client.post(ApiEndpoints.authLogout);
  }

  @override
  Future<User> me() async {
    final res = await _client.get(ApiEndpoints.authMe);
    final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return UserDto.fromJson(data);
  }
}
