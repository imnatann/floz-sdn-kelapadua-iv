import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';

class StorageService {
  static const String _boxName = 'floz_storage';
  static const String _keyToken = 'auth_token';
  static const String _keyUser = 'user_data';
  static const String _keyTenant = 'tenant_data';

  late Box _box;

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
  }

  // Token
  Future<void> saveToken(String token) async {
    await _box.put(_keyToken, token);
  }

  Future<String?> getToken() async {
    return _box.get(_keyToken);
  }

  Future<void> deleteToken() async {
    await _box.delete(_keyToken);
  }

  // Tenant
  Future<void> saveTenant(Map<String, dynamic> tenant) async {
    await _box.put(_keyTenant, jsonEncode(tenant));
  }

  Future<Map<String, dynamic>?> getTenant() async {
    final String? data = _box.get(_keyTenant);
    if (data == null) return null;
    return jsonDecode(data);
  }

  Future<String?> getTenantSlug() async {
    final tenant = await getTenant();
    return tenant?['domain']; // maps to slug/domain in search result
  }

  Future<void> deleteTenant() async {
    await _box.delete(_keyTenant);
  }

  // User
  Future<void> saveUser(Map<String, dynamic> user) async {
    await _box.put(_keyUser, jsonEncode(user));
  }

  Future<Map<String, dynamic>?> getUser() async {
    final String? data = _box.get(_keyUser);
    if (data == null) return null;
    return jsonDecode(data);
  }

  Future<void> deleteUser() async {
    await _box.delete(_keyUser);
  }

  // Clear All (Logout completely)
  Future<void> clearAll() async {
    await _box.clear();
  }

  // Clear Auth only (keep tenant)
  Future<void> clearAuth() async {
    await deleteToken();
    await deleteUser();
  }
}
