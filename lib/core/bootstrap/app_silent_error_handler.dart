import 'dart:async';

import 'package:flutter/foundation.dart';

import '../logging/app_logger.dart';
import '../logging/technical_error_repository.dart';

/// Capture les erreurs sans les exposer à l'utilisateur simple.
class AppSilentErrorHandler {
  AppSilentErrorHandler._();

  static void install() {
    final previousFlutter = FlutterError.onError;
    FlutterError.onError = (details) {
      TechnicalErrorRepository.record(
        source: 'flutter',
        error: details.exception,
        stack: details.stack,
      );
      AppLogger.error(
        'Flutter',
        details.exceptionAsString(),
        details.exception,
        details.stack,
      );
      if (kDebugMode) {
        previousFlutter?.call(details);
        FlutterError.presentError(details);
      }
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      TechnicalErrorRepository.record(
        source: 'async',
        error: error,
        stack: stack,
      );
      AppLogger.error('Async', error.toString(), error, stack);
      return true;
    };
  }
}
