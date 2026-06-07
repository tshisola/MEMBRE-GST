import 'dart:async';

/// Timeouts de sécurité pour éviter un loader bloqué indéfiniment.
class LoadingTimeoutService {
  LoadingTimeoutService._();

  static const Duration defaultTimeout = Duration(seconds: 12);
  static const Duration startupMaxBlocking = Duration(seconds: 2);

  static Timer schedule({
    required Duration duration,
    required void Function() onTimeout,
  }) {
    return Timer(duration, onTimeout);
  }
}
