import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/constants.dart';
import '../../../app/theme.dart';
import '../../../core/auth/firebase_account_management_service.dart';
import '../../../core/auth/local_admin_auth_service.dart';
import '../../../core/auth/admin_recovery_orchestrator.dart';
import '../../../core/providers/permission_providers.dart';
import '../../../core/security/role_permission_matrix.dart';
import '../../../core/security/sensitive_action_guard.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../shared/components/pop_scope_back_guard.dart';
import '../../../shared/models/admin_staff_account_model.dart';

/// Attribution et retrait de rôles — réservé Admin autorisé.
class RoleManagementScreen extends ConsumerStatefulWidget {
  const RoleManagementScreen({super.key});

  @override
  ConsumerState<RoleManagementScreen> createState() =>
      _RoleManagementScreenState();
}

class _RoleManagementScreenState extends ConsumerState<RoleManagementScreen> {
  final _auth = LocalAdminAuthService();
  final _firebase = FirebaseAccountManagementService();
  final _guard = const SensitiveActionGuard();
  List<AdminStaffAccount> _staff = [];
  bool _loading = true;

  static const _assignableRoles = [
    AppConstants.roleAdminGeneral,
    AppConstants.roleAdmin,
    AppConstants.roleAttendanceOperator,
    AppConstants.roleMediaLead,
    AppConstants.roleMediaOperator,
    AppConstants.roleDepartmentChief,
    AppConstants.rolePasteur,
    AppConstants.roleDisciple,
    AppConstants.roleLeader,
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _auth.listStaff();
    if (mounted) {
      setState(() {
        _staff = list;
        _loading = false;
      });
    }
  }

  Future<void> _assignRole(AdminStaffAccount account, String role) async {
    final userRole = await ref.read(currentUserRoleProvider.future);
    if (!_guard.canAssignRoles(userRole)) {
      _toast('Vous n\'êtes pas autorisé.');
      return;
    }
    if (account.isOwner && role != AppConstants.roleAdminGeneralOwner) {
      if (!(userRole?.hasRole(AppConstants.roleAdminGeneralOwner) ?? false)) {
        _toast('Vous n\'êtes pas autorisé.');
        return;
      }
    }
    if (role == AppConstants.roleAdminGeneralOwner &&
        !(userRole?.hasRole(AppConstants.roleAdminGeneralOwner) ?? false)) {
      _toast('Vous n\'êtes pas autorisé.');
      return;
    }

    final perms = RolePermissionMatrix.permissionsForRole(role);
    await _auth.updateStaffRole(
      accountId: account.id,
      role: role,
      actorId: userRole?.uid ?? 'admin',
      permissions: perms,
    );

    if (account.firebaseUid != null && account.firebaseUid!.isNotEmpty) {
      await _firebase.assignRole(uid: account.firebaseUid!, role: role);
    }

    await AdminRecoverySyncService.instance.runAfterRecovery(
      trigger: 'role_assign',
    );
    _toast('Rôle mis à jour.');
    await _load();
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return PopScopeBackGuard(
      fallbackRoute: '/admin/accounts',
      child: Scaffold(
        backgroundColor: AppTheme.premiumBlack,
        appBar: AppBar(
          leading: const AppBackButton(fallbackRoute: '/admin/accounts'),
          title: const Text('Gestion des rôles'),
          backgroundColor: AppTheme.cardDark,
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _staff.length,
                itemBuilder: (_, i) {
                  final account = _staff[i];
                  return Card(
                    color: AppTheme.cardDark,
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(account.displayName),
                      subtitle: Text(
                        '${account.role}${account.isOwner ? ' · Principal' : ''}',
                        style: const TextStyle(color: AppTheme.textMuted),
                      ),
                      trailing: account.isOwner
                          ? null
                          : PopupMenuButton<String>(
                              onSelected: (r) => _assignRole(account, r),
                              itemBuilder: (_) => _assignableRoles
                                  .map(
                                    (r) => PopupMenuItem(value: r, child: Text(r)),
                                  )
                                  .toList(),
                              icon: const Icon(Icons.admin_panel_settings_outlined),
                            ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
