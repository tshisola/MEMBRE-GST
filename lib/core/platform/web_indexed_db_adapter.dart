import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import 'platform_storage_adapter.dart';

/// Web — cache IndexedDB via Hive (compatible navigateurs modernes).
class WebIndexedDbAdapter implements PlatformStorageAdapter {
  static const _root = 'media_lubumbashi_web';
  bool _ready = false;

  @override
  bool get isReady => _ready;

  @override
  Future<void> initialize() async {
    await Hive.initFlutter();
    _ready = true;
  }

  Future<Box<String>> _box(String name) async {
    final key = '${_root}_$name';
    if (!Hive.isBoxOpen(key)) {
      return Hive.openBox<String>(key);
    }
    return Hive.box<String>(key);
  }

  @override
  Future<void> put(String box, String key, Map<String, dynamic> value) async {
    final b = await _box(box);
    await b.put(key, jsonEncode(value));
  }

  @override
  Future<Map<String, dynamic>?> get(String box, String key) async {
    final b = await _box(box);
    final raw = b.get(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<List<Map<String, dynamic>>> getAll(String boxName) async {
    final b = await _box(boxName);
    final out = <Map<String, dynamic>>[];
    for (final raw in b.values) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          out.add(Map<String, dynamic>.from(decoded));
        }
      } catch (_) {}
    }
    return out;
  }

  @override
  Future<void> delete(String box, String key) async {
    final b = await _box(box);
    await b.delete(key);
  }

  @override
  Future<void> clearBox(String box) async {
    final b = await _box(box);
    await b.clear();
  }
}
