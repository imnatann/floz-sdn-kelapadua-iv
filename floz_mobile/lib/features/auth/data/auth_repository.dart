import '../../../../core/storage/storage_service.dart';
import '../domain/user_model.dart';
import 'auth_api.dart';

class AuthRepository {
  final AuthApi _authApi;
  final StorageService _storageService;

  AuthRepository(this._authApi, this._storageService);

  Future<User> login(String email, String password) async {
    final data = await _authApi.login(email, password);
    final token = data['token'];
    final user = User.fromJson(data['user']);

    await _storageService.saveToken(token);
    await _storageService.saveUser(user.toJson());

    return user;
  }

  Future<void> logout() async {
    await _authApi.logout();
    await _storageService.clearAuth();
  }

  Future<void> clearAll() async {
    await _authApi.logout();
    await _storageService.clearAll();
  }

  Future<User?> checkAuth() async {
    final token = await _storageService.getToken();
    if (token == null) return null;

    try {
      // Verify token with backend
      final user = await _authApi.getMe();
      await _storageService.saveUser(user.toJson()); // Update local user data
      return user;
    } catch (e) {
      // If token invalid, clear storage
      await _storageService.clearAuth();
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> searchTenants(String query) {
    return _authApi.searchTenants(query);
  }

  Future<void> saveTenant(Map<String, dynamic> tenant) async {
    await _storageService.saveTenant(tenant);
  }

  Future<Map<String, dynamic>?> getTenant() {
    return _storageService.getTenant();
  }
}
