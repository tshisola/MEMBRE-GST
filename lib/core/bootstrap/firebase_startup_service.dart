import 'dart:async';

import '../firebase/firebase_initializer.dart';
import '../logging/app_logger.dart';
import 'startup_timeout_handler.dart';

/// Firebase avec timeout court — ne bloque pas l'UI.
class FirebaseStartupService {
  FirebaseStartupService._();

  /// Spec production : 3 à 5 secondes max au démarrage.
  static const Duration startupTimeout = Duration(seconds: 4);

  static Future<FirebaseInitResult> initialize() async {
    if (FirebaseInitializer.isInitialized) {
      return const FirebaseInitResult(success: true);
    }

    return StartupTimeoutHandler.run(
      label: 'Firebase',
      timeout: startupTimeout,
      action: () => FirebaseInitializer.initialize(),
      onTimeout: () {
        FirebaseLogger.info('Timeout — poursuite en mode local');
        return FirebaseInitResult(
          success: false,
          error: TimeoutException('Firebase timeout'),
        );
      },
    );
  }
}
