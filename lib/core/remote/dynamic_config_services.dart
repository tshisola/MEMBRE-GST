import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/theme.dart';
import 'firestore_config_service.dart';
import 'models/remote_config_models.dart';

/// Thème dynamique depuis Firestore — couleurs MEDIA LUBUMBASHI.
class DynamicThemeService {
  DynamicThemeService({FirestoreConfigService? config})
      : _config = config ?? FirestoreConfigService();

  final FirestoreConfigService _config;
  RemoteThemeConfig _cached = const RemoteThemeConfig();

  RemoteThemeConfig get current => _cached;

  Future<void> loadAndApply() async {
    _cached = await _config.loadTheme();
  }

  ThemeData buildTheme() {
    final t = _cached;
    return AppTheme.darkTheme.copyWith(
      scaffoldBackgroundColor: t.background,
      colorScheme: AppTheme.darkTheme.colorScheme.copyWith(
        primary: t.primary,
        secondary: t.secondary,
        error: t.error,
      ),
      cardTheme: AppTheme.darkTheme.cardTheme?.copyWith(color: t.card),
    );
  }

  Future<void> cacheLocally(SharedPreferences prefs) async {
    await prefs.setInt('remote_theme_primary', _cached.primary.toARGB32());
    await prefs.setInt('remote_theme_bg', _cached.background.toARGB32());
  }
}

/// Alias services demandés.
typedef FeatureFlagService = DynamicFeatureFlagService;

class DynamicFeatureFlagService {
  DynamicFeatureFlagService({FirestoreConfigService? config})
      : _config = config ?? FirestoreConfigService();

  final FirestoreConfigService _config;
  Map<String, bool> _flags = {};

  Map<String, bool> get flags => Map.unmodifiable(_flags);

  Future<void> load() async {
    _flags = await _config.loadFeatureFlags();
  }

  bool isEnabled(String key, {bool defaultValue = true}) {
    return _flags[key] ?? defaultValue;
  }
}

class RemoteTextService {
  RemoteTextService({FirestoreConfigService? config})
      : _config = config ?? FirestoreConfigService();

  final FirestoreConfigService _config;
  Map<String, String> _texts = {};

  Future<void> load() async {
    _texts = await _config.loadTexts();
  }

  String text(String key, {required String fallback}) {
    final v = _texts[key];
    if (v == null || v.isEmpty) return fallback;
    return v;
  }

  Map<String, String> get all => Map.unmodifiable(_texts);
}

class DynamicMenuService {
  DynamicMenuService({FirestoreConfigService? config})
      : _config = config ?? FirestoreConfigService();

  final FirestoreConfigService _config;
  List<RemoteMenuItem> _items = [];

  List<RemoteMenuItem> get items => List.unmodifiable(_items);

  Future<void> load() async {
    _items = await _config.loadMenus();
  }

  List<RemoteMenuItem> forRole(String? role) {
    if (_items.isEmpty) return [];
    return _items.where((m) {
      if (m.roles.isEmpty) return true;
      if (role == null) return false;
      return m.roles.contains(role);
    }).toList();
  }
}

class RemoteDashboardService {
  RemoteDashboardService({FirestoreConfigService? config})
      : _config = config ?? FirestoreConfigService();

  final FirestoreConfigService _config;
  List<RemoteDashboardCard> _cards = [];

  List<RemoteDashboardCard> get cards => List.unmodifiable(_cards);

  Future<void> load() async {
    _cards = await _config.loadDashboards();
  }
}

class RemoteAttendanceRulesService {
  RemoteAttendanceRulesService({FirestoreConfigService? config})
      : _config = config ?? FirestoreConfigService();

  final FirestoreConfigService _config;
  Map<String, dynamic> _rules = {};

  Map<String, dynamic> get rules => Map.unmodifiable(_rules);

  Future<void> load() async {
    _rules = await _config.loadAttendanceRules();
  }

  double? get eligibilityThreshold {
    final v = _rules['eligibilityThreshold'];
    if (v is num) return v.toDouble();
    return null;
  }
}

class RemotePdfTemplateService {
  RemotePdfTemplateService({FirestoreConfigService? config})
      : _config = config ?? FirestoreConfigService();

  final FirestoreConfigService _config;
  Map<String, dynamic> _templates = {};

  Map<String, dynamic> get templates => Map.unmodifiable(_templates);

  Future<void> load() async {
    _templates = await _config.loadPdfTemplates();
  }
}
