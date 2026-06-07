import 'dart:async';

import '../auth/staff_firebase_provisioning_service.dart';
import '../database/database_repair_service.dart';
import '../firebase/firebase_initializer.dart';
import '../logging/app_logger.dart';
import 'sqlite_startup_service.dart';
import '../sync/auth_sync_services.dart';
import '../sync/auto_sync_manager.dart';
import '../sync/member_sync_manager.dart';
import '../production/smart_automation_engine.dart';
import '../remote/remote_update_applier.dart';
import 'app_bootstrapper.dart';
import 'firebase_startup_service.dart';
import 'local_mode_service.dart';

export 'app_bootstrapper.dart' show AppBootstrapper;

/// Aggregated startup initialization result.
class AppInitResult {
  const AppInitResult({
    required this.databaseReady,
    required this.firebaseResult,
    this.error,
    this.sqlitePending = false,
    this.allowUiLaunch = true,
    this.cloudOnlyFallback = false,
  });

  final bool databaseReady;
  final FirebaseInitResult firebaseResult;
  final Object? error;
  final bool sqlitePending;
  final bool allowUiLaunch;
  final bool cloudOnlyFallback;

  bool get firebaseReady => firebaseResult.success;
}

/// Initializes SQLite and Firebase for the IFCM Lubumbashi app.
class AppInitializer {
  AppInitializer._();

  /// SQLite d'abord, Firebase avec timeout 4s — ne bloque pas l'UI longtemps.
  static Future<AppInitResult> initialize() => AppBootstrapper.bootstrap();

  /// Cloud sync after UI is visible — never blocks LoginChoiceScreen.
  static Future<void> runDeferredSync() async {
    try {
      SQLiteStartupService.ensureOpenInBackground(
        onComplete: (ok) {
          if (ok) {
            unawaited(DatabaseRepairService.runDeferredCityMigration());
          }
        },
      );

      if (await LocalModeService.isLocalMode()) {
        final firebaseResult = await FirebaseStartupService.initialize();
        if (!firebaseResult.success) return;
        await LocalModeService.disableLocalMode();
      } else       if (!FirebaseInitializer.isInitialized) {
        final firebaseResult = await FirebaseStartupService.initialize();
        if (!firebaseResult.success) return;
      }

      await StaffFirebaseProvisioningService().provisionAllIfNeeded();

      await AuthSyncService().sync();
      await MemberAccountSyncService().sync();
      await DepartmentListSyncService().sync();
      await MemberSyncManager().syncNow(silent: true);
      await AutoSyncManager().runBackgroundSync(trigger: 'cold_start');
      await SmartAutomationEngine.instance.runPostSyncAutomations();
      if (FirebaseInitializer.isInitialized) {
        await RemoteUpdateApplier().applyAll();
      }
      AppLogger.sync('Sync différée terminée');
    } catch (e, st) {
      AppLogger.error('Sync', 'Sync différée', e, st);
    }
  }
}
