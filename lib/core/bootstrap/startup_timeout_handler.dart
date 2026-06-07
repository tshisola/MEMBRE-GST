import 'dart:async';

import '../logging/app_logger.dart';

/// Applique un timeout sans bloquer indéfiniment le démarrage.
class StartupTimeoutHandler {
  StartupTimeoutHandler._();

  static Future<T> run<T>({
    required String label,
    required Duration timeout,
    required Future<T> Function() action,
    required T Function() onTimeout,
  }) async {
    try {
      return await action().timeout(timeout, onTimeout: () {
        AppLogger.startup('$label: timeout (${timeout.inSeconds}s) — mode local');
        return onTimeout();
      });
    } catch (e, st) {
      AppLogger.error('Startup', label, e, st);
      return onTimeout();
    }
  }
}
