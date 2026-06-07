import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../app/constants.dart';

/// Persists lightweight session data locally between app launches.
class LocalSession {
  LocalSession(this._prefs);

  final SharedPreferences _prefs;

  String? get userId => _prefs.getString(AppConstants.prefSessionUserId);
  String? get email => _prefs.getString(AppConstants.prefSessionEmail);
  String? get role => _prefs.getString(AppConstants.prefSessionRole);
  String? get department => _prefs.getString(AppConstants.prefSessionDepartment);
  String? get accountType => _prefs.getString(AppConstants.prefSessionAccountType);
  String? get memberId => _prefs.getString(AppConstants.prefSessionMemberId);

  bool get mustChangePassword =>
      _prefs.getBool(AppConstants.prefSessionMustChangePassword) ?? false;

  bool get rememberMe => _prefs.getBool(AppConstants.prefRememberMe) ?? false;

  String? get loginIdentifier =>
      _prefs.getString(AppConstants.prefLastLoginIdentifier);

  bool get isMediaAttendanceOperator =>
      _prefs.getBool(AppConstants.prefIsMediaAttendanceOperator) ?? false;

  bool get isLoggedIn => userId != null && userId!.isNotEmpty;

  bool get isMemberAccount =>
      accountType == AppConstants.accountTypeMember ||
      role == AppConstants.roleMember;

  bool get isAdminAccount =>
      accountType == AppConstants.accountTypeAdmin ||
      (role != null && AppConstants.adminRoles.contains(role));

  Future<void> saveSession({
    required String userId,
    required String email,
    required String role,
    String? department,
    bool isMediaAttendanceOperator = false,
    String? accountType,
    bool mustChangePassword = false,
    String? memberId,
    bool rememberMe = false,
    String? loginIdentifier,
    List<String>? permissions,
    String? displayName,
    bool isOwner = false,
  }) async {
    await _prefs.setString(AppConstants.prefSessionUserId, userId);
    await _prefs.setString(AppConstants.prefSessionEmail, email);
    await _prefs.setString(AppConstants.prefSessionRole, role);
    if (department != null) {
      await _prefs.setString(AppConstants.prefSessionDepartment, department);
    }
    await _prefs.setBool(
      AppConstants.prefIsMediaAttendanceOperator,
      isMediaAttendanceOperator,
    );
    if (accountType != null) {
      await _prefs.setString(AppConstants.prefSessionAccountType, accountType);
    }
    await _prefs.setBool(
      AppConstants.prefSessionMustChangePassword,
      mustChangePassword,
    );
    if (memberId != null) {
      await _prefs.setString(AppConstants.prefSessionMemberId, memberId);
    }
    await _prefs.setBool(AppConstants.prefRememberMe, rememberMe);
    if (rememberMe && loginIdentifier != null && loginIdentifier.isNotEmpty) {
      await _prefs.setString(
        AppConstants.prefLastLoginIdentifier,
        loginIdentifier,
      );
    } else {
      await _prefs.remove(AppConstants.prefLastLoginIdentifier);
    }
    if (permissions != null) {
      await _prefs.setString(
        AppConstants.prefSessionPermissions,
        jsonEncode(permissions),
      );
    }
    if (displayName != null) {
      await _prefs.setString(AppConstants.prefSessionDisplayName, displayName);
    }
    await _prefs.setBool(AppConstants.prefSessionIsOwner, isOwner);
  }

  Future<void> clearSession() async {
    await _prefs.remove(AppConstants.prefSessionUserId);
    await _prefs.remove(AppConstants.prefSessionEmail);
    await _prefs.remove(AppConstants.prefSessionRole);
    await _prefs.remove(AppConstants.prefSessionDepartment);
    await _prefs.remove(AppConstants.prefIsMediaAttendanceOperator);
    await _prefs.remove(AppConstants.prefSessionAccountType);
    await _prefs.remove(AppConstants.prefSessionMustChangePassword);
    await _prefs.remove(AppConstants.prefSessionMemberId);
    await _prefs.remove(AppConstants.prefRememberMe);
    await _prefs.remove(AppConstants.prefLastLoginIdentifier);
    await _prefs.remove(AppConstants.prefFirebaseUid);
    await _prefs.remove(AppConstants.prefGooglePhotoUrl);
    await _prefs.remove(AppConstants.prefGoogleDisplayName);
    await _prefs.remove(AppConstants.prefActivationStatus);
    await _prefs.remove(AppConstants.prefAuthProvider);
    await _prefs.remove(AppConstants.prefSessionPermissions);
    await _prefs.remove(AppConstants.prefSessionDisplayName);
    await _prefs.remove(AppConstants.prefSessionIsOwner);
  }

  Future<void> clearMustChangePassword() async {
    await _prefs.setBool(AppConstants.prefSessionMustChangePassword, false);
  }

  bool hasRole(String requiredRole) => role == requiredRole;

  String? get firebaseUid => _prefs.getString(AppConstants.prefFirebaseUid);
  String? get googlePhotoUrl => _prefs.getString(AppConstants.prefGooglePhotoUrl);
  String? get googleDisplayName =>
      _prefs.getString(AppConstants.prefGoogleDisplayName);
  String? get activationStatus =>
      _prefs.getString(AppConstants.prefActivationStatus);
  String? get authProvider => _prefs.getString(AppConstants.prefAuthProvider);

  List<String> get permissions {
    final raw = _prefs.getString(AppConstants.prefSessionPermissions);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
    } catch (_) {}
    return const [];
  }

  String? get displayName =>
      _prefs.getString(AppConstants.prefSessionDisplayName);

  bool get isOwnerAccount =>
      _prefs.getBool(AppConstants.prefSessionIsOwner) ?? false;

  bool get isAdminGeneralOwner =>
      role == AppConstants.roleAdminGeneralOwner || isOwnerAccount;

  bool hasPermission(String permission) => permissions.contains(permission);

  bool get isGoogleMediaMember =>
      authProvider == AppConstants.authProviderGoogle &&
      role == AppConstants.roleMediaMember;

  bool get isPendingMediaActivation =>
      activationStatus == AppConstants.activationStatusPending;

  Future<void> saveGoogleMediaSession({
    required String firebaseUid,
    required String email,
    String? displayName,
    String? photoUrl,
    required String role,
    String? memberId,
    required String activationStatus,
  }) async {
    await saveSession(
      userId: firebaseUid,
      email: email,
      role: role,
      department: AppConstants.mediaDepartmentId,
      accountType: AppConstants.accountTypeMember,
      mustChangePassword: false,
      memberId: memberId,
      isMediaAttendanceOperator: false,
    );
    await _prefs.setString(AppConstants.prefFirebaseUid, firebaseUid);
    await _prefs.setString(AppConstants.prefAuthProvider, AppConstants.authProviderGoogle);
    await _prefs.setString(AppConstants.prefActivationStatus, activationStatus);
    if (displayName != null) {
      await _prefs.setString(AppConstants.prefGoogleDisplayName, displayName);
    }
    if (photoUrl != null) {
      await _prefs.setString(AppConstants.prefGooglePhotoUrl, photoUrl);
    }
  }

  bool hasAnyRole(List<String> roles) => role != null && roles.contains(role);
}

/// Clears session and ensures login fields are never pre-filled after logout.
Future<void> logoutAndClearLoginState(SharedPreferences prefs) async {
  final session = LocalSession(prefs);
  await session.clearSession();
}
