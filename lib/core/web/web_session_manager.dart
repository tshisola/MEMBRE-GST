import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/constants.dart';
import '../firebase/firebase_initializer.dart';
import '../storage/local_session.dart';
import 'web_user_profile_repository.dart';

/// Restaure la session locale depuis Firebase Auth après refresh navigateur.
class WebSessionManager {
  WebSessionManager({
    WebUserProfileRepository? profiles,
  }) : _profiles = profiles ?? WebUserProfileRepository();

  final WebUserProfileRepository _profiles;

  static WebSessionManager? _instance;
  factory WebSessionManager.instance() =>
      _instance ??= WebSessionManager();

  Future<bool> restoreSessionIfNeeded(SharedPreferences prefs) async {
    if (!kIsWeb || !FirebaseInitializer.isInitialized) return false;

    final session = LocalSession(prefs);
    if (session.isLoggedIn) return true;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final profile = await _profiles.loadByUid(
        uid: user.uid,
        email: user.email,
      );
      if (profile == null) return false;

      final isOperator =
          profile.role == AppConstants.roleAttendanceOperator;

      await session.saveSession(
        userId: profile.uid,
        email: profile.email ?? user.email ?? '',
        role: profile.role,
        department: profile.departmentId ?? AppConstants.mediaDepartmentId,
        accountType: profile.accountType,
        mustChangePassword: profile.mustChangePassword,
        isMediaAttendanceOperator: isOperator,
        memberId: profile.memberId,
        permissions: profile.permissions,
        displayName: profile.displayName,
        isOwner: profile.isOwner,
      );
      await prefs.setString(AppConstants.prefFirebaseUid, user.uid);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> signOut(SharedPreferences prefs) async {
    if (FirebaseInitializer.isInitialized) {
      await FirebaseAuth.instance.signOut();
    }
    await LocalSession(prefs).clearSession();
  }
}

/// Alias demandé.
typedef WebAuthStateProvider = WebSessionManager;
