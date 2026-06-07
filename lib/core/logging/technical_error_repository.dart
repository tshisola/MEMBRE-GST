import 'dart:async';

import 'package:flutter/foundation.dart';

import '../messaging/user_facing_messages.dart';
import 'error_reporter_local.dart';

/// Stocke les erreurs techniques — visibles uniquement dans Diagnostic Admin.
class TechnicalErrorRepository {
  TechnicalErrorRepository._();

  static final List<TechnicalErrorEntry> _entries = [];
  static const _maxEntries = 80;

  static void record({
    required String source,
    required Object error,
    StackTrace? stack,
  }) {
    final entry = TechnicalErrorEntry(
      source: source,
      message: error.toString(),
      stack: stack?.toString(),
      at: DateTime.now(),
    );
    _entries.insert(0, entry);
    if (_entries.length > _maxEntries) {
      _entries.removeRange(_maxEntries, _entries.length);
    }

    unawaited(
      ErrorReporterLocal.record(
        category: source,
        message: entry.message,
        stackTrace: entry.stack,
      ),
    );

    if (kDebugMode) {
      debugPrint('[Technical][$source] ${entry.message}');
    }
  }

  static List<TechnicalErrorEntry> get recent => List.unmodifiable(_entries);

  static TechnicalErrorEntry? get last =>
      _entries.isEmpty ? null : _entries.first;

  /// Message sûr pour l'UI publique (masque SQLite, timeout, stack, chemins).
  static String sanitizeForUser(Object? error, {String? fallback}) {
    if (error == null) {
      return fallback ?? UserFacingMessages.genericIssue;
    }
    final raw = error.toString().toLowerCase();
    const blocked = [
      'sqlite',
      'timeout',
      'exception',
      'stack',
      'pragma',
      'database',
      'firestore',
      'firebase',
      'sqflite',
      'migration',
      'rules',
      'permission denied',
      'cloud_firestore',
      'dart:',
      'package:',
      '/data/',
      'lib/',
    ];
    for (final token in blocked) {
      if (raw.contains(token)) {
        return fallback ?? UserFacingMessages.genericIssue;
      }
    }
    if (raw.length > 120) {
      return fallback ?? UserFacingMessages.genericIssue;
    }
    return fallback ?? UserFacingMessages.genericIssue;
  }
}

class TechnicalErrorEntry {
  const TechnicalErrorEntry({
    required this.source,
    required this.message,
    this.stack,
    required this.at,
  });

  final String source;
  final String message;
  final String? stack;
  final DateTime at;
}
