import 'package:flutter/material.dart';

/// Modèles configuration distante — Firestore / Remote Config.
class RemoteAppConfig {
  const RemoteAppConfig({
    this.appDisplayName,
    this.city,
    this.syncIntervalMinutes = 15,
    this.configVersion = '1',
    this.updatedAt,
  });

  final String? appDisplayName;
  final String? city;
  final int syncIntervalMinutes;
  final String configVersion;
  final String? updatedAt;

  factory RemoteAppConfig.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const RemoteAppConfig();
    return RemoteAppConfig(
      appDisplayName: data['appDisplayName'] as String?,
      city: data['city'] as String?,
      syncIntervalMinutes: data['syncIntervalMinutes'] as int? ?? 15,
      configVersion: data['configVersion']?.toString() ?? '1',
      updatedAt: data['updatedAt'] as String?,
    );
  }
}

class RemoteThemeConfig {
  const RemoteThemeConfig({
    this.background = const Color(0xFF050505),
    this.card = const Color(0xFF111827),
    this.primary = const Color(0xFFF45A1F),
    this.secondary = const Color(0xFF0067B1),
    this.accent = const Color(0xFFD4AF37),
    this.success = const Color(0xFF22C55E),
    this.error = const Color(0xFFEF4444),
    this.textPrimary = const Color(0xFFFFFFFF),
    this.textMuted = const Color(0xFF9CA3AF),
  });

  final Color background;
  final Color card;
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color success;
  final Color error;
  final Color textPrimary;
  final Color textMuted;

  factory RemoteThemeConfig.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const RemoteThemeConfig();
    return RemoteThemeConfig(
      background: _color(data['background'], 0xFF050505),
      card: _color(data['card'], 0xFF111827),
      primary: _color(data['primary'], 0xFFF45A1F),
      secondary: _color(data['secondary'], 0xFF0067B1),
      accent: _color(data['accent'], 0xFFD4AF37),
      success: _color(data['success'], 0xFF22C55E),
      error: _color(data['error'], 0xFFEF4444),
      textPrimary: _color(data['textPrimary'], 0xFFFFFFFF),
      textMuted: _color(data['textMuted'], 0xFF9CA3AF),
    );
  }

  static Color _color(dynamic v, int fallback) {
    if (v is int) return Color(v);
    if (v is String && v.startsWith('#')) {
      final hex = v.replaceFirst('#', '');
      final value = int.tryParse(hex.length == 6 ? 'FF$hex' : hex, radix: 16);
      if (value != null) return Color(value);
    }
    return Color(fallback);
  }
}

class RemoteMenuItem {
  const RemoteMenuItem({
    required this.id,
    required this.label,
    required this.route,
    this.icon,
    this.visible = true,
    this.order = 0,
    this.roles = const [],
  });

  final String id;
  final String label;
  final String route;
  final String? icon;
  final bool visible;
  final int order;
  final List<String> roles;

  factory RemoteMenuItem.fromMap(Map<String, dynamic> data) {
    return RemoteMenuItem(
      id: data['id'] as String? ?? '',
      label: data['label'] as String? ?? '',
      route: data['route'] as String? ?? '/',
      icon: data['icon'] as String?,
      visible: data['visible'] != false,
      order: data['order'] as int? ?? 0,
      roles: (data['roles'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }
}

class RemoteDashboardCard {
  const RemoteDashboardCard({
    required this.id,
    required this.title,
    this.subtitle,
    this.icon,
    this.route,
    this.visible = true,
    this.order = 0,
  });

  final String id;
  final String title;
  final String? subtitle;
  final String? icon;
  final String? route;
  final bool visible;
  final int order;

  factory RemoteDashboardCard.fromMap(Map<String, dynamic> data) {
    return RemoteDashboardCard(
      id: data['id'] as String? ?? '',
      title: data['title'] as String? ?? '',
      subtitle: data['subtitle'] as String?,
      icon: data['icon'] as String?,
      route: data['route'] as String?,
      visible: data['visible'] != false,
      order: data['order'] as int? ?? 0,
    );
  }
}

class RemoteComponentSpec {
  const RemoteComponentSpec({
    required this.type,
    required this.id,
    this.props = const {},
    this.children = const [],
  });

  final String type;
  final String id;
  final Map<String, dynamic> props;
  final List<RemoteComponentSpec> children;

  factory RemoteComponentSpec.fromMap(Map<String, dynamic> data) {
    final childrenRaw = data['children'] as List?;
    return RemoteComponentSpec(
      type: data['type'] as String? ?? 'unknown',
      id: data['id'] as String? ?? '',
      props: Map<String, dynamic>.from(data['props'] as Map? ?? {}),
      children: childrenRaw
              ?.whereType<Map>()
              .map((e) => RemoteComponentSpec.fromMap(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
    );
  }
}

class AppVersionInfo {
  const AppVersionInfo({
    this.androidMinVersion,
    this.androidLatestVersion,
    this.webLatestVersion,
    this.configVersion,
    this.releaseNotes,
    this.updatedAt,
  });

  final String? androidMinVersion;
  final String? androidLatestVersion;
  final String? webLatestVersion;
  final String? configVersion;
  final String? releaseNotes;
  final String? updatedAt;

  factory AppVersionInfo.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const AppVersionInfo();
    return AppVersionInfo(
      androidMinVersion: data['android_min_version'] as String?,
      androidLatestVersion: data['android_latest_version'] as String?,
      webLatestVersion: data['web_latest_version'] as String?,
      configVersion: data['config_version']?.toString(),
      releaseNotes: data['releaseNotes'] as String?,
      updatedAt: data['updatedAt'] as String?,
    );
  }
}

/// Types de composants autorisés (Server-Driven UI — pas de code arbitraire).
class AllowedRemoteComponentTypes {
  AllowedRemoteComponentTypes._();

  static const card = 'card';
  static const stat = 'stat';
  static const actionButton = 'action_button';
  static const menuItem = 'menu_item';
  static const listColumn = 'list_column';
  static const banner = 'banner';
  static const section = 'section';

  static const all = {
    card,
    stat,
    actionButton,
    menuItem,
    listColumn,
    banner,
    section,
  };

  static bool isAllowed(String type) => all.contains(type);
}
