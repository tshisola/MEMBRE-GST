import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/constants.dart';
import '../../shared/models/admin_staff_account_model.dart';
import '../firebase/firebase_auth_service.dart';
import '../firebase/firebase_initializer.dart';
import '../messaging/auth_error_sanitizer.dart';
import '../providers/app_providers.dart';
import '../providers/background_sync_providers.dart';
import '../storage/local_session.dart';
import '../members/member_created_broadcaster.dart';
import '../sync/sync_on_login_service.dart';
import '../web/web_admin_login_service.dart';
import '../web/web_member_login_service.dart';
import '../web/web_role_redirector.dart';
import 'auth_form_controller.dart';
import 'auth_role_redirector.dart';
import 'admin_firebase_auth_bridge.dart';
import 'local_admin_auth_service.dart';
import 'member_auth_service.dart';
/// Orchestrates admin and member login flows.
class LoginController {
  LoginController({
    required this.form,
    required this.ref,
    MemberAuthService? memberAuth,
    LocalAdminAuthService? adminAuth,
  })  : _memberAuth = memberAuth ?? MemberAuthService(),
        _adminAuth = adminAuth ?? LocalAdminAuthService();

  final AuthFormController form;
  final WidgetRef ref;
  final MemberAuthService _memberAuth;
  final LocalAdminAuthService _adminAuth;
  final WebAdminLoginService _webAdminLogin = WebAdminLoginService();
  final WebMemberLoginService _webMemberLogin = WebMemberLoginService();

  Future<AuthRedirectResult> signInAdmin() async {
    form.setLoading(true);
    form.setError(null);
    try {
      final identifier = form.identifierController.text.trim();
      final password = form.passwordController.text;

      if (identifier.isEmpty || password.isEmpty) {
        return AuthRedirectResult.error('Identifiant et mot de passe requis.');
      }

      if (kIsWeb) {
        return _signInAdminWeb(identifier: identifier, password: password);
      }

      final localResult = await _adminAuth.authenticate(
        identifier: identifier,
        password: password,
      );

      if (localResult.isDisabled) {
        return AuthRedirectResult.route('/auth/account-disabled');
      }

      AdminStaffAccount? staffAccount = localResult.account;

      if (!localResult.success &&
          FirebaseInitializer.isInitialized &&
          identifier.contains('@')) {
        await FirebaseAuthService().signInWithEmail(
          email: identifier,
          password: password,
        );
        staffAccount = await _adminAuth.findByLogin(identifier.split('@').first);
        staffAccount ??= await _adminAuth.findByLogin(identifier);
      }

      if (staffAccount == null && !localResult.success) {
        return AuthRedirectResult.error(
          localResult.message ?? 'Identifiant ou mot de passe incorrect.',
        );
      }

      staffAccount ??= localResult.account;
      if (staffAccount == null) {
        return AuthRedirectResult.error('Identifiant ou mot de passe incorrect.');
      }

      if (localResult.success) {
        await AdminFirebaseAuthBridge().signInAfterLocalAuth(
          account: staffAccount,
          password: password,
        );
      }

      final prefs = await ref.read(sharedPreferencesProvider.future);
      final session = LocalSession(prefs);
      final isAttendanceOperator =
          staffAccount.role == AppConstants.roleAttendanceOperator;

      await session.saveSession(
        userId: staffAccount.id,
        email: staffAccount.email ?? identifier,
        role: staffAccount.role,
        department: AppConstants.mediaDepartmentId,
        accountType: AppConstants.accountTypeAdmin,
        mustChangePassword: staffAccount.mustChangePassword,
        isMediaAttendanceOperator: isAttendanceOperator,
        rememberMe: form.rememberMe,
        loginIdentifier: form.rememberMe ? identifier : null,
        permissions: staffAccount.permissions,
        displayName: staffAccount.displayName,
        isOwner: staffAccount.isOwner,
      );

      ref.invalidate(localSessionProvider);
      unawaited(
        SyncOnLoginService(autoSync: ref.read(autoSyncManagerProvider))
            .afterLogin(session),
      );
      unawaited(MemberCreatedBroadcaster.instance.afterStaffLogin(
        session,
        account: staffAccount,
      ));

      if (staffAccount.mustChangePassword) {
        return AuthRedirectResult.route('/auth/change-password');
      }
      return AuthRoleRedirector.redirectForRole(staffAccount.role);
    } catch (e) {
      return AuthRedirectResult.error(AuthErrorSanitizer.sanitize(e));
    } finally {
      form.setLoading(false);
    }
  }

  Future<AuthRedirectResult> _signInAdminWeb({
    required String identifier,
    required String password,
  }) async {
    final cloudResult = await _webAdminLogin.authenticate(
      identifier: identifier,
      password: password,
    );

    if (cloudResult.isDisabled) {
      return AuthRedirectResult.route('/auth/account-disabled');
    }

    if (!cloudResult.success || cloudResult.account == null) {
      return AuthRedirectResult.error(
        cloudResult.message ?? 'Identifiant ou mot de passe incorrect.',
      );
    }

    final staffAccount = cloudResult.account!;
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final session = LocalSession(prefs);
    final isAttendanceOperator =
        staffAccount.role == AppConstants.roleAttendanceOperator;

    await session.saveSession(
      userId: staffAccount.id,
      email: staffAccount.email ?? identifier,
      role: staffAccount.role,
      department: AppConstants.mediaDepartmentId,
      accountType: AppConstants.accountTypeAdmin,
      mustChangePassword: staffAccount.mustChangePassword,
      isMediaAttendanceOperator: isAttendanceOperator,
      rememberMe: form.rememberMe,
      loginIdentifier: form.rememberMe ? identifier : null,
      permissions: staffAccount.permissions,
      displayName: staffAccount.displayName,
      isOwner: staffAccount.isOwner,
    );
    if (staffAccount.firebaseUid != null) {
      await prefs.setString(
        AppConstants.prefFirebaseUid,
        staffAccount.firebaseUid!,
      );
    }

    ref.invalidate(localSessionProvider);
    unawaited(
      SyncOnLoginService(autoSync: ref.read(autoSyncManagerProvider))
          .afterLogin(session),
    );
    unawaited(MemberCreatedBroadcaster.instance.afterStaffLogin(
      session,
      account: staffAccount,
    ));

    if (staffAccount.mustChangePassword) {
      return AuthRedirectResult.route('/auth/change-password');
    }
    return WebRoleRedirector.redirectForProfile(
      role: staffAccount.role,
      accountType: AppConstants.accountTypeAdmin,
    );
  }

  Future<AuthRedirectResult> signInMember() async {
    form.setLoading(true);
    form.setError(null);
    try {
      final identifier = form.identifierController.text.trim();
      final password = form.passwordController.text;

      if (identifier.isEmpty || password.isEmpty) {
        return AuthRedirectResult.error('Identifiant et mot de passe requis.');
      }

      if (kIsWeb) {
        return _signInMemberWeb(identifier: identifier, password: password);
      }

      final result = await _memberAuth.authenticate(
        identifier: identifier,
        password: password,
      );

      if (!result.success) {
        if (result.isDisabled) {
          return AuthRedirectResult.route('/auth/account-disabled');
        }
        return AuthRedirectResult.error(result.message ?? 'Connexion échouée.');
      }

      final prefs = await ref.read(sharedPreferencesProvider.future);
      final session = LocalSession(prefs);

      await session.saveSession(
        userId: result.account!.id,
        email: result.account!.email ?? '',
        role: AppConstants.roleMember,
        department: result.account!.departmentId,
        accountType: AppConstants.accountTypeMember,
        mustChangePassword: result.account!.mustChangePassword,
        memberId: result.account!.memberId,
        rememberMe: form.rememberMe,
        loginIdentifier: form.rememberMe ? identifier : null,
      );

      ref.invalidate(localSessionProvider);

      unawaited(
        SyncOnLoginService(autoSync: ref.read(autoSyncManagerProvider))
            .afterLogin(session),
      );

      if (result.account!.mustChangePassword) {
        return AuthRedirectResult.route('/auth/change-password');
      }
      return AuthRedirectResult.route('/member/dashboard');
    } catch (e) {
      return AuthRedirectResult.error(AuthErrorSanitizer.sanitize(e));
    } finally {
      form.setLoading(false);
    }
  }

  Future<AuthRedirectResult> _signInMemberWeb({
    required String identifier,
    required String password,
  }) async {
    final cloudResult = await _webMemberLogin.authenticate(
      identifier: identifier,
      password: password,
    );

    if (cloudResult.isDisabled) {
      return AuthRedirectResult.route('/auth/account-disabled');
    }

    if (!cloudResult.success || cloudResult.account == null) {
      return AuthRedirectResult.error(
        cloudResult.message ?? 'Identifiant ou mot de passe incorrect.',
      );
    }

    final memberAccount = cloudResult.account!;
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final session = LocalSession(prefs);

    await session.saveSession(
      userId: memberAccount.id,
      email: memberAccount.email ?? identifier,
      role: AppConstants.roleMember,
      department: memberAccount.departmentId,
      accountType: AppConstants.accountTypeMember,
      mustChangePassword: memberAccount.mustChangePassword,
      memberId: memberAccount.memberId,
      rememberMe: form.rememberMe,
      loginIdentifier: form.rememberMe ? identifier : null,
    );
    await prefs.setString(
      AppConstants.prefFirebaseUid,
      memberAccount.id,
    );

    ref.invalidate(localSessionProvider);

    if (memberAccount.mustChangePassword) {
      return AuthRedirectResult.route('/auth/change-password');
    }
    return WebRoleRedirector.redirectForProfile(
      role: AppConstants.roleMember,
      accountType: AppConstants.accountTypeMember,
    );
  }
}

final authFormControllerProvider =
    ChangeNotifierProvider.autoDispose<AuthFormController>(
  (ref) => AuthFormController(),
);
