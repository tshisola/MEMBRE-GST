import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/members/member_deletion.dart';
import '../../../core/advanced/automation/advanced_automation_center.dart';
import '../../../core/smart/automation/smart_automation_center.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/permission_providers.dart';
import '../../../features/admin_realtime/presentation/members_live_provider.dart';
import '../../../features/members/data/local_member_repository.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../shared/components/auth_ui_kit.dart';
import '../../../shared/components/pop_scope_back_guard.dart';
import '../../../shared/components/premium_ui_kit.dart';
import '../../../shared/components/smart_ui_kit.dart';
import '../../../shared/models/ifcm_member_record.dart';
import '../../smart/presentation/smart_providers.dart';

enum _DeleteStep { reason, confirm, success }

/// Flux suppression membre : motif → confirmation → succès.
class DeleteMemberScreen extends ConsumerStatefulWidget {
  const DeleteMemberScreen({super.key, required this.memberId});

  final String memberId;

  @override
  ConsumerState<DeleteMemberScreen> createState() => _DeleteMemberScreenState();
}

class _DeleteMemberScreenState extends ConsumerState<DeleteMemberScreen> {
  final _reasonController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  _DeleteStep _step = _DeleteStep.reason;
  bool _confirmed = false;
  bool _loading = false;
  bool _obscurePassword = true;
  String? _resultMessage;
  bool _isRequest = false;

  @override
  void dispose() {
    _reasonController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit(IfcmMemberRecord member) async {
    if (!_confirmed) {
      _showSnack('Veuillez confirmer la suppression.');
      return;
    }
    if (_confirmController.text.trim().toUpperCase() != 'SUPPRIMER') {
      _showSnack('Tapez SUPPRIMER pour confirmer.');
      return;
    }

    setState(() => _loading = true);
    final role = await ref.read(currentUserRoleProvider.future);
    final session = await ref.read(localSessionProvider.future);
    if (role == null) {
      setState(() => _loading = false);
      _showSnack('Session expirée.');
      return;
    }

    final result = await MemberDeletionService().execute(
      actor: role,
      actorName: session.displayName ?? session.email ?? 'Admin',
      member: member,
      reason: _reasonController.text.trim(),
      adminPassword: _passwordController.text,
    );

    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.success) {
        _step = _DeleteStep.success;
        _resultMessage = result.message;
        _isRequest = result.isRequest;
        bumpMembersRevision(ref);
        unawaited(SmartAutomationCenter.instance.onMemberDeleted());
        unawaited(AdvancedAutomationCenter.instance.onMemberDeleted(member.displayName));
      } else {
        _showSnack(result.message ?? 'Action impossible.');
      }
    });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.surfaceElevated),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<IfcmMemberRecord?>(
      future: LocalMemberRepository().getById(widget.memberId),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: AppTheme.premiumBlack,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final member = snap.data;
        if (member == null) {
          return PopScopeBackGuard(
            fallbackRoute: '/members',
            child: Scaffold(
            backgroundColor: AppTheme.premiumBlack,
            appBar: AppBar(
              leading: const AppBackButton(fallbackRoute: '/members'),
              title: const Text('Supprimer membre'),
            ),
            body: const Center(child: Text('Membre introuvable')),
          ),
          );
        }

        return PopScopeBackGuard(
          fallbackRoute: '/members',
          child: Scaffold(
          backgroundColor: AppTheme.premiumBlack,
          appBar: AppBar(
            backgroundColor: AppTheme.premiumBlack,
            leading: const AppBackButton(fallbackRoute: '/members'),
            title: const Text('Supprimer membre'),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: AuthFormCard(
                    accentColor: AppTheme.danger,
                    child: _step == _DeleteStep.success
                        ? _buildSuccess()
                        : _step == _DeleteStep.confirm
                            ? _buildConfirm(member)
                            : _buildReason(member),
                  ),
                ),
              ),
            ),
          ),
        ),
        );
      },
    );
  }

  Widget _buildReason(IfcmMemberRecord member) {
    final impactAsync = ref.watch(deletionImpactProvider(member.id));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          member.displayName,
          style: authTextStyle(weight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        impactAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (_, __) => const SizedBox.shrink(),
          data: (impact) => DeleteImpactPreviewCard(report: impact),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _reasonController,
          maxLines: 3,
          style: authTextStyle(),
          decoration: const InputDecoration(
            labelText: 'Motif de suppression (obligatoire)',
            hintText: 'Indiquez le motif…',
          ),
        ),
        const SizedBox(height: 20),
        AdvancedButton(
          label: 'Continuer',
          variant: AdvancedButtonVariant.sync,
          onPressed: () {
            if (_reasonController.text.trim().length < 5) {
              _showSnack('Veuillez indiquer un motif de suppression.');
              return;
            }
            setState(() => _step = _DeleteStep.confirm);
          },
        ),
        const SizedBox(height: 10),
        AdvancedButton(
          label: 'Annuler',
          variant: AdvancedButtonVariant.secondary,
          onPressed: () => context.pop(),
        ),
      ],
    );
  }

  Widget _buildConfirm(IfcmMemberRecord member) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.warning_amber_rounded, color: AppTheme.danger, size: 48),
        const SizedBox(height: 12),
        Text(
          'Voulez-vous vraiment supprimer ce membre ? '
          'Cette action sera enregistrée et pourra être restaurée par l\'Admin Général.',
          style: authTextStyle(),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          member.displayName,
          style: authTextStyle(weight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        PasswordInputField(
          controller: _passwordController,
          obscure: _obscurePassword,
          onToggleVisibility: () =>
              setState(() => _obscurePassword = !_obscurePassword),
          label: 'Mot de passe administrateur',
        ),
        const SizedBox(height: 12),
        SecureInputField(
          controller: _confirmController,
          label: 'Confirmation',
          hint: 'Tapez SUPPRIMER',
          prefixIcon: Icons.edit,
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          value: _confirmed,
          onChanged: (v) => setState(() => _confirmed = v ?? false),
          title: Text(
            'Je confirme vouloir supprimer ce membre',
            style: authTextStyle(),
          ),
          activeColor: AppTheme.goldAccent,
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 16),
        AdvancedButton(
          label: 'Supprimer membre',
          variant: AdvancedButtonVariant.danger,
          isLoading: _loading,
          onPressed: _loading ? null : () => _submit(member),
        ),
        const SizedBox(height: 10),
        AdvancedButton(
          label: 'Retour',
          variant: AdvancedButtonVariant.secondary,
          onPressed: _loading ? null : () => setState(() => _step = _DeleteStep.reason),
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          _isRequest ? Icons.hourglass_top : Icons.check_circle_outline,
          color: _isRequest ? AppTheme.goldAccent : Colors.greenAccent,
          size: 56,
        ),
        const SizedBox(height: 16),
        Text(
          _isRequest ? 'Demande enregistrée' : 'Membre supprimé avec succès',
          style: authTextStyle(weight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          _resultMessage ?? '',
          style: authTextStyle(color: AppTheme.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        AdvancedButton(
          label: 'Retour au registre',
          onPressed: () => context.go('/members'),
        ),
        if (!_isRequest) ...[
          const SizedBox(height: 10),
          AdvancedButton(
            label: 'Voir la corbeille',
            variant: AdvancedButtonVariant.sync,
            onPressed: () => context.go('/members/trash'),
          ),
        ],
      ],
    );
  }
}
