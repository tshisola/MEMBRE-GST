import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persists recent errors for the Admin diagnostic screen.
class ErrorReporterLocal {
  ErrorReporterLocal._();

  static const _key = 'ifcm_error_log_v1';
  static const _routeKey = 'ifcm_last_route_v1';
  static const _maxEntries = 80;

  static String? lastRoute;

  static Future<void> record({
    required String category,
    required String message,
    String? stackTrace,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_key) ?? [];
      final entry = jsonEncode({
        'at': DateTime.now().toIso8601String(),
        'category': category,
        'message': message,
        if (stackTrace != null) 'stack': stackTrace,
      });
      raw.insert(0, entry);
      while (raw.length > _maxEntries) {
        raw.removeLast();
      }
      await prefs.setStringList(_key, raw);
    } catch (_) {}
  }

  static Future<void> setLastRoute(String route) async {
    lastRoute = route;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_routeKey, route);
    } catch (_) {}
  }

  static Future<String?> getLastRoute() async {
    if (lastRoute != null) return lastRoute;
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_routeKey);
    } catch (_) {
      return null;
    }
  }

  static Future<List<DiagnosticLogEntry>> loadEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_key) ?? [];
      return raw.map((line) {
        try {
          final map = jsonDecode(line) as Map<String, dynamic>;
          return DiagnosticLogEntry(
            at: DateTime.tryParse(map['at'] as String? ?? '') ?? DateTime.now(),
            category: map['category'] as String? ?? '?',
            message: map['message'] as String? ?? line,
            stackTrace: map['stack'] as String?,
          );
        } catch (_) {
          return DiagnosticLogEntry(
            at: DateTime.now(),
            category: 'legacy',
            message: line,
          );
        }
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

class DiagnosticLogEntry {
  const DiagnosticLogEntry({
    required this.at,
    required this.category,
    required this.message,
    this.stackTrace,
  });

  final DateTime at;
  final String category;
  final String message;
  final String? stackTrace;
}
