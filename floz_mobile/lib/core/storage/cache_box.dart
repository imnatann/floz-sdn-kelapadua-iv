import 'package:hive_flutter/hive_flutter.dart';

class CacheBox<T> {
  final String name;
  final Duration ttl;

  CacheBox({required this.name, required this.ttl});

  Future<Box> _open() async {
    return Hive.isBoxOpen(name) ? Hive.box(name) : await Hive.openBox(name);
  }

  Future<void> put(String key, dynamic value) async {
    final box = await _open();
    await box.put(key, {
      'value': value,
      'cached_at': DateTime.now().toIso8601String(),
    });
  }

  /// Returns the value if present and not expired, else null.
  Future<dynamic> get(String key) async {
    final box = await _open();
    final raw = box.get(key);
    if (raw is! Map) return null;
    final cachedAt = DateTime.tryParse(raw['cached_at'] as String? ?? '');
    if (cachedAt == null) return null;
    if (DateTime.now().difference(cachedAt) > ttl) {
      return null;
    }
    return raw['value'];
  }

  /// Returns the value regardless of TTL (for stale-fallback on network error).
  Future<dynamic> getStale(String key) async {
    final box = await _open();
    final raw = box.get(key);
    if (raw is! Map) return null;
    return raw['value'];
  }

  Future<void> invalidate(String key) async {
    final box = await _open();
    await box.delete(key);
  }

  Future<void> clearAll() async {
    final box = await _open();
    await box.clear();
  }
}
