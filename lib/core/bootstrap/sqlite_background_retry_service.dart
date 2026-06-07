import 'dart:async';

import '../database/database_manager.dart';
import '../logging/technical_error_repository.dart';
import 'sqlite_startup_service.dart';

/// Réessaie l'ouverture SQLite en arrière-plan sans bloquer l'UI.
class SQLiteBackgroundRetryService {
  SQLiteBackgroundRetryService._();

  static Timer? _timer;
  static int _attempts = 0;
  static const _maxAttempts = 12;

  static void start() {
    _timer?.cancel();
    _attempts = 0;
    scheduleRetry();
  }

  static void scheduleRetry({Duration delay = const Duration(seconds: 8)}) {
    _timer?.cancel();
    if (_attempts >= _maxAttempts) return;
    _timer = Timer(delay, () async {
      _attempts++;
      if (DatabaseManager.instance.isReady) return;
      try {
        SQLiteStartupService.ensureOpenInBackground(
          onComplete: (ok) {
            if (!ok && _attempts < _maxAttempts) {
              scheduleRetry(delay: const Duration(seconds: 15));
            }
          },
        );
      } catch (e, st) {
        TechnicalErrorRepository.record(
          source: 'sqlite_retry',
          error: e,
          stack: st,
        );
        if (_attempts < _maxAttempts) {
          scheduleRetry(delay: const Duration(seconds: 20));
        }
      }
    });
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
