import 'dart:async';

import '../database/database_manager.dart';
import '../database/database_repair_service.dart';
import '../logging/technical_error_repository.dart';
import '../sync/cloud_only_fallback_service.dart';
import 'sqlite_background_retry_service.dart';
import 'sqlite_startup_service.dart';

/// Récupération silencieuse au démarrage — aucun message technique à l'utilisateur.
class SilentStartupRecoveryService {
  SilentStartupRecoveryService._();

  static bool _started = false;

  static void start() {
    if (_started) return;
    _started = true;
    SQLiteBackgroundRetryService.start();
    unawaited(_recover());
  }

  static Future<void> _recover() async {
    try {
      if (!DatabaseManager.instance.isReady) {
        SQLiteStartupService.ensureOpenInBackground(
          onComplete: (ok) async {
            if (ok) {
              await DatabaseRepairService.runDeferredCityMigration();
            } else {
              await _tryCloudFallback();
            }
          },
        );
      } else {
        await DatabaseRepairService.runDeferredCityMigration();
      }
    } catch (e, st) {
      TechnicalErrorRepository.record(
        source: 'startup_recovery',
        error: e,
        stack: st,
      );
      await _tryCloudFallback();
      SQLiteBackgroundRetryService.scheduleRetry();
    }
  }

  static Future<void> _tryCloudFallback() async {
    try {
      if (await CloudOnlyFallbackService.canUse()) {
        await CloudOnlyFallbackService.enable();
      }
    } catch (e, st) {
      TechnicalErrorRepository.record(
        source: 'cloud_fallback',
        error: e,
        stack: st,
      );
    }
  }
}
