import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/constants.dart';
import '../../../app/theme.dart';
import '../../../core/auth/local_account_management_service.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/permission_providers.dart';
import '../../../core/security/sensitive_action_guard.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../shared/components/pop_scope_back_guard.dart';
import '../../../shared/components/auth_ui_kit.dart';
import '../../../shared/models/admin_staff_account_model.dart';

/// Hub gestion comptes staff — Admin Général / Owner.
class AdminAccountManagementScreen extends ConsumerStatefulWidget {
  const AdminAccountManagementScreen({super.key});

  @override
  ConsumerState<AdminAccountManagementScreen> createState() =>
      _AdminAccountManagementScreenState();
}

class _AdminAccountManagementScreenState
    extends ConsumerState<AdminAccountManagementScreen> {
  final _mgmt = LocalAccountManagementService();
  final _sensitive = const SensitiveActionGuard();
  List<AdminStaffAccount> _staff = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final role = await ref.read(currentUserRoleProvider.future);
    final list = await _mgmt.listStaff(role);
    if (mounted) {
      setState(() {
        _staff = list;
        _loading = false;
      });
    }
  }

  Future<void> _resetStaff(AdminStaffAccount account) async {
    final role = await ref.read(currentUserRoleProvider.future);
    if (role == null || !_sensitive.canResetPasswords(role)) {
      _toast('Vous n\'êtes pas autorisé.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: Text('Réinitialiser', style: authTextStyle(weight: FontWeight.w600)),
        content: Text(
          'Réinitialiser le mot de passe de ${account.displayName} ?',
          style: authTextStyle(color: AppTheme.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annuler', style: authTextStyle(color: AppTheme.textMuted)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final outcome = await _mgmt.resetStaffPassword(
      actor: role,
      accountId: account.id,
    );
    if (outcome == null || !mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: Text('Mot de passe provisoire', style: authTextStyle(weight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(account.displayName, style: authTextStyle(weight: FontWeight.w600)),
            const SizedBox(height: 8),
            SelectableText(
              outcome.temporaryPassword,
              style: authTextStyle(color: AppTheme.goldLight, weight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Affichage unique — communiquez ce mot de passe en personne.',
              style: authTextStyle(color: AppTheme.textMuted),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('J\'ai noté'),
          ),
        ],
      ),
    );
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.cardSecondary),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScopeBackGuard(
      fallbackRoute: '/dashboard',
      child: Scaffold(
      backgroundColor: AppTheme.premiumBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.cardDark,
        leading: const AppBackButton(fallbackRoute: '/dashboard'),
        title: const Text('Gestion des comptes'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.goldAccent))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Responsables',
                  style: authTextStyle(weight: FontWeight.w700),
                ),
                Text(
                  'Comptes staff MEDIA LUBUMBASHI',
                  style: authTextStyle(color: AppTheme.textMuted),
                ),
                const SizedBox(height: 12),
                _QuickLink(
                  icon: Icons.person_add_outlined,
                  label: 'Créer compte Admin',
                  onTap: () => context.push('/admin/accounts/create-admin'),
                ),
                _QuickLink(
                  icon: Icons.badge_outlined,
                  label: 'Créer compte Opérateur',
                  onTap: () => context.push('/admin/accounts/create-operator'),
                ),
                ..._staff.map((a) => _StaffCard(
                      account: a,
                      onReset: () => _resetStaff(a),
                    )),
                const SizedBox(height: 20),
                _QuickLink(
                  icon: Icons.admin_panel_settings_outlined,
                  label: 'Gestion des rôles',
                  onTap: () => context.push('/admin/accounts/roles'),
                ),
                _QuickLink(
                  icon: Icons.people_outline,
                  label: 'Comptes membres',
                  onTap: () => context.push('/admin/member-accounts'),
                ),
                _QuickLink(
                  icon: Icons.security,
                  label: 'Historique sécurité',
                  onTap: () => context.push('/admin/audit-logs'),
                ),
                _QuickLink(
                  icon: Icons.chat_bubble_outline,
                  label: 'Messagerie',
                  onTap: () => context.push('/messaging'),
                ),
                _QuickLink(
                  icon: Icons.event_outlined,
                  label: 'Rendez-vous',
                  onTap: () => context.push('/appointments'),
                ),
                _QuickLink(
                  icon: Icons.auto_awesome,
                  label: 'Assistant IA MEDIA',
                  onTap: () => context.push('/ai/assistant'),
                ),
                if (ref.watch(isAdminOwnerProvider).valueOrNull == true)
                  _QuickLink(
                    icon: Icons.healing_outlined,
                    label: 'Diagnostic application',
                    onTap: () => context.push('/admin/sync/diagnostic'),
                  ),
              ],
            ),
    ),
    );
  }
}

class _StaffCard extends StatelessWidget {
  const _StaffCard({required this.account, required this.onReset});

  final AdminStaffAccount account;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final roleColor = account.isOwner
        ? AppTheme.brandOrange
        : account.role == AppConstants.roleAdminGeneral
            ? AppTheme.goldAccent
            : AppTheme.brandBlue;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: roleColor.withValues(alpha: 0.2),
            child: Icon(Icons.person, color: roleColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.displayName,
                  style: authTextStyle(weight: FontWeight.w600),
                ),
                Text(
                  account.loginIdentifier,
                  style: authTextStyle(color: AppTheme.textMuted),
                ),
                Text(
                  account.role,
                  style: authTextStyle(color: roleColor, weight: FontWeight.w500),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Réinitialiser mot de passe',
            onPressed: onReset,
            icon: const Icon(Icons.lock_reset, color: AppTheme.goldLight),
          ),
        ],
      ),
    );
  }
}

class _QuickLink extends StatelessWidget {
  const _QuickLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.brandBlue),
      title: Text(label, style: authTextStyle()),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
      onTap: onTap,
    );
  }
}
