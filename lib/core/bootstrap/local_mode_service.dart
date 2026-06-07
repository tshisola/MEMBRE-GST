import 'package:shared_preferences/shared_preferences.dart';

import '../logging/app_logger.dart';

/// Mode local explicite quand Firebase est indisponible ou lent.
class LocalModeService {
  LocalModeService._();

  static const _key = 'ifcm_force_local_mode_v1';

  static Future<bool> isLocalMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  static Future<void> enableLocalMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
    AppLogger.startup('Mode local activé manuellement');
  }

  static Future<void> disableLocalMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, false);
    AppLogger.startup('Mode local désactivé — sync Firebase autorisée');
  }
}
