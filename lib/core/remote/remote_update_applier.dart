import 'package:shared_preferences/shared_preferences.dart';

import '../../app/constants.dart';
import 'dynamic_config_services.dart';
import 'firestore_config_service.dart';
import 'models/remote_config_models.dart';
import 'remote_config_service.dart';

/// Vérification version configuration cloud.
class ConfigVersionChecker {
  ConfigVersionChecker({
    FirestoreConfigService? firestore,
    RemoteConfigService? remote,
  })  : _firestore = firestore ?? FirestoreConfigService(),
        _remote = remote ?? RemoteConfigService();

  final FirestoreConfigService _firestore;
  final RemoteConfigService _remote;

  Future<ConfigVersionResult> check(SharedPreferences prefs) async {
    await _remote.fetchAndActivate();
    final appConfig = await _firestore.loadAppConfig();
    final versions = await _firestore.loadAppVersions();

    final remoteVersion = versions.configVersion ??
        appConfig.configVersion ??
        _remote.configVersion;
    final cached = prefs.getString(AppConstants.prefCachedConfigVersion);

    return ConfigVersionResult(
      remoteVersion: remoteVersion,
      cachedVersion: cached,
      needsUpdate: cached == null || cached != remoteVersion,
      appVersions: versions,
    );
  }
}

class ConfigVersionResult {
  const ConfigVersionResult({
    required this.remoteVersion,
    this.cachedVersion,
    required this.needsUpdate,
    this.appVersions = const AppVersionInfo(),
  });

  final String remoteVersion;
  final String? cachedVersion;
  final bool needsUpdate;
  final AppVersionInfo appVersions;
}

/// Version application — Android / Web / config.
class AppVersionService {
  AppVersionService({FirestoreConfigService? config})
      : _config = config ?? FirestoreConfigService();

  final FirestoreConfigService _config;

  Future<AppVersionInfo> load() => _config.loadAppVersions();

  Future<String?> webLatestVersion() async {
    final info = await load();
    return info.webLatestVersion;
  }
}

/// Applique toute la configuration distante en mémoire + cache local.
class RemoteUpdateApplier {
  RemoteUpdateApplier({
    RemoteConfigService? remote,
    FirestoreConfigService? firestore,
    DynamicThemeService? theme,
    DynamicFeatureFlagService? flags,
    RemoteTextService? texts,
    DynamicMenuService? menus,
    RemoteDashboardService? dashboards,
    RemoteAttendanceRulesService? attendance,
    RemotePdfTemplateService? pdf,
  })  : _remote = remote ?? RemoteConfigService(),
        _firestore = firestore ?? FirestoreConfigService(),
        _theme = theme ?? DynamicThemeService(),
        _flags = flags ?? DynamicFeatureFlagService(),
        _texts = texts ?? RemoteTextService(),
        _menus = menus ?? DynamicMenuService(),
        _dashboards = dashboards ?? RemoteDashboardService(),
        _attendance = attendance ?? RemoteAttendanceRulesService(),
        _pdf = pdf ?? RemotePdfTemplateService();

  final RemoteConfigService _remote;
  final FirestoreConfigService _firestore;
  final DynamicThemeService _theme;
  final DynamicFeatureFlagService _flags;
  final RemoteTextService _texts;
  final DynamicMenuService _menus;
  final RemoteDashboardService _dashboards;
  final RemoteAttendanceRulesService _attendance;
  final RemotePdfTemplateService _pdf;

  DynamicThemeService get theme => _theme;
  DynamicFeatureFlagService get flags => _flags;
  RemoteTextService get texts => _texts;
  DynamicMenuService get menus => _menus;
  RemoteDashboardService get dashboards => _dashboards;
  RemoteAttendanceRulesService get attendance => _attendance;
  RemotePdfTemplateService get pdf => _pdf;

  Future<RemoteApplyResult> applyAll({SharedPreferences? prefs}) async {
    await _remote.fetchAndActivate();
    await _theme.loadAndApply();
    await _flags.load();
    await _texts.load();
    await _menus.load();
    await _dashboards.load();
    await _attendance.load();
    await _pdf.load();

    final appConfig = await _firestore.loadAppConfig();
    final versions = await _firestore.loadAppVersions();
    final version = versions.configVersion ?? appConfig.configVersion ?? _remote.configVersion;

    if (prefs != null) {
      await prefs.setString(AppConstants.prefCachedConfigVersion, version);
      await _theme.cacheLocally(prefs);
    }

    return RemoteApplyResult(
      success: true,
      configVersion: version,
      message: 'Configuration mise à jour.',
    );
  }
}

class RemoteApplyResult {
  const RemoteApplyResult({
    required this.success,
    this.configVersion,
    this.message,
  });

  final bool success;
  final String? configVersion;
  final String? message;
}
