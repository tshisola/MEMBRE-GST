import 'package:flutter/foundation.dart';

import '../logging/app_logger.dart';

/// Mesure simple des opérations lourdes (debug / diagnostic).
class PerformanceMonitor {
  PerformanceMonitor._();

  static Future<T> track<T>(String label, Future<T> Function() action) async {
    final sw = Stopwatch()..start();
    try {
      return await action();
    } finally {
      sw.stop();
      if (sw.elapsedMilliseconds > 500) {
        AppLogger.startup('$label: ${sw.elapsedMilliseconds}ms');
      }
    }
  }
}
