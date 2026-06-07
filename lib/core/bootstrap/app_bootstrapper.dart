import 'dart:async';

import '../firebase/firebase_initializer.dart';
import '../auth/super_admin_bootstrap_service.dart';
import '../sync/cloud_only_fallback_service.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../platform/platform_storage_adapter.dart';
import '../web/firebase_web_sync_service.dart';
import '../web/web_background_sync_service.dart';
import '../web/web_firebase_config_checker.dart';
import '../web/web_realtime_service.dart';
import '../web/web_session_manager.dart';
import 'app_initializer.dart';
import 'firebase_startup_service.dart';
import 'local_mode_service.dart';
import 'sqlite_startup_service.dart';

/// Orchestrateur : SQLite rapide (non bloquant), Firebase en parallèle court.
class AppBootstrapper {
  AppBootstrapper._();

  static Future<AppInitResult> bootstrap() async {
    final sqlite = await SQLiteStartupService.initialize();
    final sqliteReady = sqlite.ready;
    final sqlitePending = sqlite.pendingBackground || !sqliteReady;

    if (sqlitePending && !sqliteReady) {
      SQLiteStartupService.ensureOpenInBackground();
    }

    if (sqliteReady) {
      unawaited(SuperAdminBootstrapService().run());
    }

    final forceLocal = await LocalModeService.isLocalMode();
    FirebaseInitResult firebaseResult;
    if (forceLocal) {
      firebaseResult = const FirebaseInitResult(success: false);
    } else {
      firebaseResult = await FirebaseStartupService.initialize();
      if (!firebaseResult.success) {
        await LocalModeService.enableLocalMode();
      } else {
        await LocalModeService.disableLocalMode();
      }
    }

    final cloudFallback = !sqliteReady && firebaseResult.success;
    if (cloudFallback) {
      await CloudOnlyFallbackService.enable();
    }

    if (kIsWeb && firebaseResult.success) {
      await FirebaseWebInitializer.ensureInitialized();
      await PlatformStorageAdapter.instance.initialize();
      await FirebaseWebSyncService.instance.start();
      WebBackgroundSyncService.instance.start();
      WebFirestoreRealtimeListener.instance.startAll();
      try {
        final prefs = await SharedPreferences.getInstance();
        await WebSessionManager.instance().restoreSessionIfNeeded(prefs);
      } catch (_) {}
    }

    return AppInitResult(
      databaseReady: sqliteReady,
      sqlitePending: sqlitePending,
      allowUiLaunch: true,
      firebaseResult: firebaseResult,
      cloudOnlyFallback: cloudFallback,
      error: sqlite.error ?? firebaseResult.error,
    );
  }
}
