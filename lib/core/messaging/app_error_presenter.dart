import 'hidden_technical_log_service.dart';
import 'secure_error_mapper.dart';
import 'user_facing_messages.dart';

/// Présente les messages à l'utilisateur — logs techniques ailleurs.
class AppErrorPresenter {
  AppErrorPresenter._();

  static String forUser(
    Object? error, {
    String source = 'ui',
    String? fallback,
    StackTrace? stack,
  }) {
    if (error != null) {
      HiddenTechnicalLogService.record(
        source: source,
        error: error,
        stack: stack,
      );
    }
    return SecureErrorMapper.map(error, fallback: fallback);
  }

  static String forSnackBar(Object? error, {String source = 'ui'}) {
    return forUser(
      error,
      source: source,
      fallback: UserFacingMessages.genericIssue,
    );
  }

  static void recordOnly(Object error, {String source = 'ui', StackTrace? stack}) {
    HiddenTechnicalLogService.record(source: source, error: error, stack: stack);
  }
}

/// Alias demandé — même comportement qu'[AppErrorPresenter].
typedef AppMessagePresenter = AppErrorPresenter;
