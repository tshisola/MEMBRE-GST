import 'dart:async';

import 'package:sqflite/sqflite.dart';

import '../logging/app_logger.dart';
import 'database_helper.dart';

/// Statut global de la base locale (pour badges UI).
enum DatabaseOpenStatus {
  idle,
  opening,
  ready,
  pendingBackground,
  failed,
  repairing,
}

/// Singleton — une seule ouverture SQLite à la fois, verrou anti-deadlock.
class DatabaseManager {
  DatabaseManager._();

  static final DatabaseManager instance = DatabaseManager._();

  DatabaseOpenStatus status = DatabaseOpenStatus.idle;
  String? lastError;
  String? dbPath;
  int? openDurationMs;
  DateTime? lastOpenedAt;

  Future<Database>? _opening;
  Database? _cached;

  /// Ouvre la base (réutilise le même Future si déjà en cours).
  Future<Database> open({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (_cached != null && _cached!.isOpen) {
      status = DatabaseOpenStatus.ready;
      return _cached!;
    }

    _opening ??= _completeOpen();

    try {
      return await _opening!.timeout(timeout);
    } on TimeoutException {
      status = DatabaseOpenStatus.pendingBackground;
      rethrow;
    }
  }

  Future<Database> _completeOpen() async {
    status = DatabaseOpenStatus.opening;
    final sw = Stopwatch()..start();
    try {
      final db = await _doOpen();
      _cached = db;
      dbPath = db.path;
      openDurationMs = sw.elapsedMilliseconds;
      lastOpenedAt = DateTime.now();
      status = DatabaseOpenStatus.ready;
      SQLiteLogger.info('Ouverte en ${openDurationMs}ms ($dbPath)');
      return db;
    } catch (e, st) {
      status = DatabaseOpenStatus.failed;
      lastError = e.toString();
      SQLiteLogger.error('Ouverture échouée', e, st);
      rethrow;
    } finally {
      _opening = null;
    }
  }

  Future<Database> _doOpen() => DatabaseHelper.instance.openRaw();

  /// Tente une ouverture rapide sans bloquer l'UI longtemps.
  Future<bool> tryQuickOpen({Duration timeout = const Duration(seconds: 5)}) async {
    try {
      await open(timeout: timeout);
      return true;
    } catch (_) {
      status = DatabaseOpenStatus.pendingBackground;
      return false;
    }
  }

  /// Continue l'ouverture en arrière-plan après affichage LoginChoice.
  void continueOpenInBackground({void Function(bool ok)? onComplete}) {
    if (status == DatabaseOpenStatus.ready) {
      onComplete?.call(true);
      return;
    }
    status = DatabaseOpenStatus.pendingBackground;
    unawaited(() async {
      try {
        await open(timeout: const Duration(seconds: 45));
        onComplete?.call(true);
      } catch (_) {
        onComplete?.call(false);
      }
    }());
  }

  void invalidateCache() {
    _cached = null;
    _opening = null;
    status = DatabaseOpenStatus.idle;
  }

  bool get isReady =>
      status == DatabaseOpenStatus.ready &&
      _cached != null &&
      _cached!.isOpen;
}
