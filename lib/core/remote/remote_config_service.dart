import 'package:firebase_remote_config/firebase_remote_config.dart';

import '../firebase/firebase_initializer.dart';
import '../logging/technical_error_repository.dart';

/// Firebase Remote Config — paramètres distants simples.
class RemoteConfigService {
  RemoteConfigService({FirebaseRemoteConfig? remoteConfig})
      : _remote = remoteConfig ?? FirebaseRemoteConfig.instance;

  final FirebaseRemoteConfig _remote;

  bool get isAvailable => FirebaseInitializer.isInitialized;

  Future<void> fetchAndActivate() async {
    if (!isAvailable) return;
    try {
      await _remote.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(minutes: 5),
      ));
      await _remote.setDefaults(const {
        'config_version': '1',
        'sync_enabled': true,
        'maintenance_mode': false,
        'announcement_banner': '',
      });
      await _remote.fetchAndActivate();
    } catch (e, st) {
      TechnicalErrorRepository.record(
        source: 'remote_config_fetch',
        error: e,
        stack: st,
      );
    }
  }

  String get configVersion => _remote.getString('config_version');
  bool get syncEnabled => _remote.getBool('sync_enabled');
  bool get maintenanceMode => _remote.getBool('maintenance_mode');
  String get announcementBanner => _remote.getString('announcement_banner');
}
