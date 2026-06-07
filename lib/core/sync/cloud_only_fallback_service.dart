import '../firebase/firebase_initializer.dart';
import '../logging/app_logger.dart';

/// Mode cloud temporaire si SQLite est indisponible mais Internet/Firebase OK.
class CloudOnlyFallbackService {
  CloudOnlyFallbackService._();

  static bool _active = false;

  static bool get isActive => _active;

  static Future<bool> canUse() async {
    if (!FirebaseInitializer.isInitialized) {
      final r = await FirebaseInitializer.initialize();
      if (!r.success) return false;
    }
    return FirebaseInitializer.isInitialized;
  }

  static Future<void> enable() async {
    if (!await canUse()) return;
    _active = true;
    AppLogger.startup('Mode en ligne temporaire activé');
  }

  static void disable() {
    _active = false;
  }
}
