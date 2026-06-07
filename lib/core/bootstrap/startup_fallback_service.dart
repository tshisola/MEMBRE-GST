import 'silent_startup_recovery_service.dart';

/// Point d'entrée fallback démarrage (alias pour orchestration).
class StartupFallbackService {
  StartupFallbackService._();

  static void ensureBackgroundRecovery() {
    SilentStartupRecoveryService.start();
  }
}
