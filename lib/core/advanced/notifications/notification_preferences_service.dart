import 'package:shared_preferences/shared_preferences.dart';

/// Préférences notifications — persistance locale.
class NotificationPreferencesService {
  NotificationPreferencesService(this._prefs);

  final SharedPreferences _prefs;

  static const _criticalKey = 'notif_pref_critical';
  static const _listsKey = 'notif_pref_lists';
  static const _accountsKey = 'notif_pref_accounts';

  bool get criticalAlerts => _prefs.getBool(_criticalKey) ?? true;
  bool get listsAndAttendance => _prefs.getBool(_listsKey) ?? true;
  bool get accountsAndActivation => _prefs.getBool(_accountsKey) ?? true;

  Future<void> setCriticalAlerts(bool value) async {
    await _prefs.setBool(_criticalKey, value);
  }

  Future<void> setListsAndAttendance(bool value) async {
    await _prefs.setBool(_listsKey, value);
  }

  Future<void> setAccountsAndActivation(bool value) async {
    await _prefs.setBool(_accountsKey, value);
  }
}
