import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/storage_service.dart';
import '../data/auth_api.dart';
import '../data/auth_repository.dart';
import '../domain/user_model.dart';

// Dependencies
final storageServiceProvider = Provider((ref) => StorageService());

final apiClientProvider = Provider((ref) {
  final storage = ref.watch(storageServiceProvider);
  return ApiClient(storage);
});

final authApiProvider = Provider((ref) {
  final client = ref.watch(apiClientProvider);
  return AuthApi(client);
});

final authRepositoryProvider = Provider((ref) {
  final api = ref.watch(authApiProvider);
  final storage = ref.watch(storageServiceProvider);
  return AuthRepository(api, storage);
});

// State
class AuthState {
  final bool isLoading;
  final User? user;
  final Map<String, dynamic>? tenant;
  final String? error;

  AuthState({this.isLoading = false, this.user, this.tenant, this.error});

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    bool? isLoading,
    User? user,
    Map<String, dynamic>? tenant,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      tenant: tenant ?? this.tenant,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(AuthState());

  Future<void> checkAuth() async {
    state = state.copyWith(isLoading: true);
    try {
      final tenant = await _repository.getTenant();
      // If no tenant selected, we can't be logged in (unless we support multi-tenant user which we don't yet)
      if (tenant == null) {
        state = state.copyWith(isLoading: false, tenant: null, user: null);
        return;
      }

      final user = await _repository.checkAuth();
      state = state.copyWith(isLoading: false, user: user, tenant: tenant);
    } catch (e) {
      state = state.copyWith(isLoading: false, user: null, error: e.toString());
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repository.login(email, password);
      state = state.copyWith(isLoading: false, user: user);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await _repository.logout();
    // Reset state but keep tenant
    state = AuthState(tenant: state.tenant);
  }

  Future<void> selectTenant(Map<String, dynamic> tenant) async {
    await _repository.saveTenant(tenant);
    state = state.copyWith(tenant: tenant);
  }

  Future<void> clearTenant() async {
    state = state.copyWith(isLoading: true);
    await _repository.clearAll();
    state = AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo);
});
