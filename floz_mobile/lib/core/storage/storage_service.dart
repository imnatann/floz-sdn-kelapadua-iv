import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';

class StorageService {
  static const String _boxName = 'floz_storage';
  static const String _keyToken = 'auth_token';
  static const String _keyUser = 'user_data';

  late Box _box;

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
  }

  Future<void> saveToken(String token) async {
    await _box.put(_keyToken, token);
  }

  Future<String?> getToken() async {
    return _box.get(_keyToken);
  }

  Future<void> deleteToken() async {
    await _box.delete(_keyToken);
  }

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

  Future<void> clearAll() async {
    await _box.clear();
  }

  Future<void> clearAuth() async {
    await deleteToken();
    await deleteUser();
  }
}
