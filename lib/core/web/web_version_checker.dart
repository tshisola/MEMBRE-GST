import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/constants.dart';
import '../logging/technical_error_repository.dart';

/// Vérifie si une nouvelle version Web est disponible (version.json).
class WebVersionChecker {
  WebVersionChecker({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _versionPath = '/version.json';

  Future<WebVersionCheckResult> check({SharedPreferences? prefs}) async {
    if (!kIsWeb) {
      return const WebVersionCheckResult(updateAvailable: false);
    }

    try {
      final uri = Uri.base.resolve(_versionPath);
      final response = await _client.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        return const WebVersionCheckResult(updateAvailable: false);
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final remoteVersion = data['webLatestVersion']?.toString() ??
          data['configVersion']?.toString() ??
          '';
      final cached = prefs?.getString(AppConstants.prefCachedWebVersion);

      return WebVersionCheckResult(
        updateAvailable: cached != null &&
            remoteVersion.isNotEmpty &&
            cached != remoteVersion,
        remoteVersion: remoteVersion,
        cachedVersion: cached,
        releaseNotes: data['releaseNotes'] as String?,
      );
    } catch (e, st) {
      TechnicalErrorRepository.record(
        source: 'web_version_check',
        error: e,
        stack: st,
      );
      return const WebVersionCheckResult(updateAvailable: false);
    }
  }

  Future<void> markCurrentVersion(String version, SharedPreferences prefs) async {
    await prefs.setString(AppConstants.prefCachedWebVersion, version);
  }
}

class WebVersionCheckResult {
  const WebVersionCheckResult({
    required this.updateAvailable,
    this.remoteVersion,
    this.cachedVersion,
    this.releaseNotes,
  });

  final bool updateAvailable;
  final String? remoteVersion;
  final String? cachedVersion;
  final String? releaseNotes;
}

/// Cache PWA — rechargement propre après mise à jour.
class WebPwaCacheService {
  const WebPwaCacheService();

  Future<void> reloadApp() async {
    if (!kIsWeb) return;
    // ignore: avoid_web_libraries_in_flutter
    // Rechargement navigateur natif via dart:html serait ideal ;
    // pour compatibilité multi-plateforme, on laisse le caller gérer.
  }
}
