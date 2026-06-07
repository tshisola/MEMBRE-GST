import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'firebase_config.dart';

/// Result of a Firebase initialization attempt.
class FirebaseInitResult {
  const FirebaseInitResult({
    required this.success,
    this.error,
  });

  final bool success;
  final Object? error;

  bool get isOfflineMode => !success;
}

/// Initializes Firebase with graceful error handling for offline/dev use.
class FirebaseInitializer {
  FirebaseInitializer._();

  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  static Future<FirebaseInitResult> initialize() async {
    if (_initialized) {
      return const FirebaseInitResult(success: true);
    }

    try {
      if (kIsWeb) {
        await Firebase.initializeApp(options: FirebaseConfig.web);
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        // Android should prefer native google-services.json bootstrap.
        await Firebase.initializeApp();
      } else {
        final appId = FirebaseConfig.currentPlatform.appId;
        if (appId.contains('REPLACE_ME') || appId.isEmpty) {
          debugPrint(
            '[Firebase] Configuration placeholder — démarrage en mode local uniquement.',
          );
          return const FirebaseInitResult(
            success: false,
            error: 'Firebase non configuré (appId placeholder)',
          );
        }
        await Firebase.initializeApp(options: FirebaseConfig.currentPlatform);
      }
      _initialized = true;
      debugPrint('[Firebase] Initialized (project: ${FirebaseConfig.projectId})');
      return const FirebaseInitResult(success: true);
    } catch (error, stackTrace) {
      debugPrint('[Firebase] Init failed — running in offline mode: $error');
      debugPrint('$stackTrace');
      return FirebaseInitResult(success: false, error: error);
    }
  }

  static void resetForTesting() {
    _initialized = false;
  }
}
