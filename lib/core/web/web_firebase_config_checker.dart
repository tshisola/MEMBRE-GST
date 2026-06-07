import 'package:flutter/foundation.dart';

import '../firebase/firebase_config.dart';
import '../firebase/firebase_initializer.dart';

/// Vérifie que le Web utilise le même projet Firebase que le mobile.
class WebFirebaseConfigChecker {
  WebFirebaseConfigChecker._();

  static const expectedProjectId = FirebaseConfig.projectId;

  static bool get isWebPlatform => kIsWeb;

  static bool validateProject({String? projectId}) {
    if (!kIsWeb) return true;
    final id = projectId ?? FirebaseConfig.projectId;
    return id == expectedProjectId;
  }

  static WebFirebaseValidationResult check() {
    if (!kIsWeb) {
      return const WebFirebaseValidationResult(
        valid: true,
        projectId: FirebaseConfig.projectId,
      );
    }
    return WebFirebaseValidationResult(
      valid: FirebaseInitializer.isInitialized &&
          FirebaseConfig.projectId == expectedProjectId,
      projectId: FirebaseConfig.projectId,
      authDomain: FirebaseConfig.web.authDomain,
      initialized: FirebaseInitializer.isInitialized,
    );
  }
}

class WebFirebaseValidationResult {
  const WebFirebaseValidationResult({
    required this.valid,
    required this.projectId,
    this.authDomain,
    this.initialized = false,
  });

  final bool valid;
  final String projectId;
  final String? authDomain;
  final bool initialized;
}

/// Alias demandé — même validation projet.
typedef WebFirebaseProjectValidator = WebFirebaseConfigChecker;

/// Initialise Firebase côté Web avec vérification projet.
class FirebaseWebInitializer {
  FirebaseWebInitializer._();

  static Future<bool> ensureInitialized() async {
    if (!kIsWeb) return FirebaseInitializer.isInitialized;
    final result = await FirebaseInitializer.initialize();
    return result.success && WebFirebaseConfigChecker.validateProject();
  }
}
