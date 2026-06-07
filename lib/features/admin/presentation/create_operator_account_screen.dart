import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/constants.dart';
import '../../../app/theme.dart';
import '../../../core/auth/account_security_service.dart';
import '../../../core/auth/local_account_management_service.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../shared/components/auth_ui_kit.dart';
import '../../../shared/components/pop_scope_back_guard.dart';
import '../../../shared/models/role_models.dart';

/// Création compte Opérateur pointage.
class CreateOperatorAccountScreen extends ConsumerStatefulWidget {
  const CreateOperatorAccountScreen({super.key});

  @override
  ConsumerState<CreateOperatorAccountScreen> createState() =>
      _CreateOperatorAccountScreenState();
}

class _CreateOperatorAccountScreenState
    extends ConsumerState<CreateOperatorAccountScreen> {
  final _loginCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _loginCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final session = await ref.read(localSessionProvider.future);
    if (session.userId == null || session.role == null) {
      setState(() {
        _busy = false;
        _error = 'Accès non autorisé.';
      });
      return;
    }
    final actor = UserRole(uid: session.userId!, roles: [session.role!]);
    if (!AccountSecurityService().canCreateOperator(actor)) {
      setState(() {
        _busy = false;
        _error = 'Accès non autorisé.';
      });
      return;
    }

    final result = await LocalAccountManagementService().createStaffAccount(
      actor: actor,
      loginIdentifier: _loginCtrl.text.trim(),
      displayName: _nameCtrl.text.trim(),
      role: AppConstants.roleAttendanceOperator,
      email: _emailCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _busy = false);
    if (result == null) {
      setState(() => _error = 'Création impossible pour le moment.');
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: Text('Compte créé', style: authTextStyle(weight: FontWeight.w600)),
        content: SelectableText(
          result.temporaryPassword,
          style: authTextStyle(color: AppTheme.goldLight, weight: FontWeight.w700),
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScopeBackGuard(
      fallbackRoute: '/admin/accounts',
      child: Scaffold(
        backgroundColor: AppTheme.premiumBlack,
        appBar: AppBar(
          leading: const AppBackButton(fallbackRoute: '/admin/accounts'),
          title: const Text('Créer compte Opérateur'),
          backgroundColor: AppTheme.cardDark,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: AuthFormCard(
            accentColor: AppTheme.brandBlue,
            child: Column(
              children: [
                TextField(
                  controller: _loginCtrl,
                  decoration: const InputDecoration(labelText: 'Identifiant'),
                ),
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nom complet'),
                ),
                TextField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(_error!, style: authTextStyle(color: AppTheme.danger)),
                  ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.brandBlue,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('Créer opérateur'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
