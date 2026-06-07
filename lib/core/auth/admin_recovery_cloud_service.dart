import 'package:cloud_functions/cloud_functions.dart';

import '../../app/constants.dart';
import '../firebase/firebase_initializer.dart';
import '../messaging/auth_error_sanitizer.dart';

/// Appels Cloud Functions récupération admin — jamais de clé privée côté client.
class AdminRecoveryCloudService {
  AdminRecoveryCloudService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  bool get isAvailable => FirebaseInitializer.isInitialized;

  Future<Map<String, dynamic>> seedOrResetVerdickOwner({
    required String email,
    bool resetPassword = true,
  }) async {
    return _call('seedOrResetVerdickOwnerAccountCallable', {
      'email': email,
      'resetPassword': resetPassword,
    });
  }

  Future<Map<String, dynamic>> seedVerdickOwner({
    required String email,
    required String displayName,
  }) async {
    return _call('seedVerdickOwnerAccountCallable', {
      'loginIdentifier': AppConstants.staffLoginVerdick,
      'email': email,
      'displayName': displayName,
      'permissions': RolePermissionMatrixOwnerPermissions.all,
    });
  }

  Future<Map<String, dynamic>> resetVerdickPassword({bool sendEmail = false}) {
    return _call('resetVerdickPasswordCallable', {
      'email': AppConstants.staffOwnerPrimaryEmail,
      'sendEmail': sendEmail,
    });
  }

  Future<Map<String, dynamic>> createJenoAdminGeneral({required String email}) {
    return _call('createJenoAdminGeneralCallable', {
      'loginIdentifier': AppConstants.staffLoginJeno,
      'email': email,
      'displayName': 'Jeno',
    });
  }

  Future<Map<String, dynamic>> resetUserPassword({
    required String uid,
    required String newPassword,
  }) {
    return _call('resetUserPasswordCallable', {
      'uid': uid,
      'newPassword': newPassword,
    });
  }

  Future<Map<String, dynamic>> assignRoleSecure({
    required String uid,
    required String role,
    List<String>? permissions,
  }) {
    return _call('assignRoleCallableSecure', {
      'uid': uid,
      'role': role,
      if (permissions != null) 'permissions': permissions,
    });
  }

  Future<Map<String, dynamic>> bootstrapOwnerRecovery({
    required String email,
  }) {
    return _call('bootstrapOwnerRecoveryCallable', {'email': email});
  }

  Future<Map<String, dynamic>> _call(
    String name,
    Map<String, dynamic> data,
  ) async {
    if (!isAvailable) return {'success': false};
    try {
      final result = await _functions.httpsCallable(name).call(data);
      final raw = result.data;
      if (raw is Map) {
        return Map<String, dynamic>.from(raw);
      }
      return {'success': true, 'data': raw};
    } catch (e) {
      throw AuthErrorSanitizer.sanitize(e);
    }
  }
}

/// Permissions owner pour seed Cloud Function.
class RolePermissionMatrixOwnerPermissions {
  RolePermissionMatrixOwnerPermissions._();
  static const all = [
    'can_manage_everything',
    'can_assign_roles',
    'can_remove_roles',
    'can_reset_passwords',
    'can_create_accounts',
    'can_activate_accounts',
    'can_disable_accounts',
    'can_delete_member',
    'can_restore_member',
    'can_view_audit_logs',
    'can_view_diagnostics',
    'can_force_sync',
    'can_manage_firebase_from_app',
  ];
}
