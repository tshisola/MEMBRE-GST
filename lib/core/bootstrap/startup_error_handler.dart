import 'app_silent_error_handler.dart';

/// @deprecated Utiliser [AppSilentErrorHandler.install].
class StartupErrorHandler {
  StartupErrorHandler._();

  static void install() => AppSilentErrorHandler.install();
}
