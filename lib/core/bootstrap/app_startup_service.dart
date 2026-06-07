import 'dart:async';

import 'package:flutter/foundation.dart';

import '../firebase/firebase_initializer.dart';
import '../logging/technical_error_repository.dart';
import 'app_initializer.dart';

enum StartupPhase {
  loading,
  success,
  error,
  offlineMode,
  degraded,
}

class StartupState {
  const StartupState({
    required this.phase,
    this.result,
  });

  final StartupPhase phase;
  final AppInitResult? result;

  bool get canLaunchApp => true;
}

/// Bootstrap silencieux — l'UI démarre toujours.
class AppStartupService {
  AppStartupService._();

  static const Duration initTimeout = Duration(seconds: 8);

  static Future<StartupState> bootstrap() async {
    try {
      final result = await AppInitializer.initialize().timeout(
        initTimeout,
        onTimeout: () {
          TechnicalErrorRepository.record(
            source: 'startup',
            error: TimeoutException('global_startup'),
          );
          return AppInitResult(
            databaseReady: false,
            sqlitePending: true,
            allowUiLaunch: true,
            firebaseResult: const FirebaseInitResult(success: false),
          );
        },
      );

      if (result.error != null) {
        TechnicalErrorRepository.record(
          source: 'startup',
          error: result.error!,
        );
      }

      if (!result.databaseReady) {
        return StartupState(phase: StartupPhase.degraded, result: result);
      }

      if (!result.firebaseReady) {
        return StartupState(phase: StartupPhase.offlineMode, result: result);
      }

      return StartupState(phase: StartupPhase.success, result: result);
    } catch (e, st) {
      TechnicalErrorRepository.record(source: 'startup', error: e, stack: st);
      debugPrint('[AppStartup] $e');
      return StartupState(
        phase: StartupPhase.degraded,
        result: AppInitResult(
          databaseReady: false,
          allowUiLaunch: true,
          firebaseResult: const FirebaseInitResult(success: false),
          error: e,
        ),
      );
    }
  }
}
