import 'package:flutter/foundation.dart';

import '../platform/platform_storage_adapter.dart';
import '../sync/cloud_only_fallback_service.dart';
import '../firebase/firebase_initializer.dart';
import '../logging/app_logger.dart';

/// Synchronisation Firebase côté Web — cache local + Firestore.
class FirebaseWebSyncService {
  FirebaseWebSyncService._();
  static final FirebaseWebSyncService instance = FirebaseWebSyncService._();

  bool _started = false;

  bool get isActive => kIsWeb && _started;

  Future<void> start() async {
    if (!kIsWeb || _started) return;
    await PlatformStorageAdapter.instance.initialize();
    if (!FirebaseInitializer.isInitialized) {
      await FirebaseInitializer.initialize();
    }
    if (FirebaseInitializer.isInitialized) {
      await CloudOnlyFallbackService.enable();
    }
    _started = true;
    AppLogger.sync('Web sync démarré');
  }

  Future<void> syncNow({String trigger = 'manual'}) async {
    if (!isActive) return;
    AppLogger.sync('Web sync ($trigger)');
  }
}

typedef WebFirebaseSyncService = FirebaseWebSyncService;
