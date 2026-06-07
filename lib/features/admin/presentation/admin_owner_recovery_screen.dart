import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/constants.dart';
import '../../../app/theme.dart';
import '../../../core/auth/admin_recovery_orchestrator.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../shared/components/auth_ui_kit.dart';
import '../../../shared/components/pop_scope_back_guard.dart';

/// Récupération Admin Général — restauration Verdick Yav + Jeno.
class AdminOwnerRecoveryScreen extends StatefulWidget {
  const AdminOwnerRecoveryScreen({super.key});

  @override
  State<AdminOwnerRecoveryScreen> createState() =>
      _AdminOwnerRecoveryScreenState();
}

class _AdminOwnerRecoveryScreenState extends State<AdminOwnerRecoveryScreen> {
  final _orchestrator = AdminRecoveryOrchestrator();
  final _jenoEmailController = TextEditingController(
    text: AppConstants.staffEmailJeno,
  );

  AdminRecoveryStatusReport? _status;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _evaluate();
  }

  @override
  void dispose() {
    _jenoEmailController.dispose();
    super.dispose();
  }

  Future<void> _evaluate() async {
    setState(() => _loading = true);
    final report = await _orchestrator.evaluate();
    if (mounted) {
      setState(() {
        _status = report;
        _loading = false;
      });
    }
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    final result = await _orchestrator.restoreVerdickOwner();
    if (!mounted) return;
    setState(() => _busy = false);
    context.push(
      '/auth/password-reset-result',
      extra: result,
    );
  }

  Future<void> _sendResetLink() async {
    setState(() => _busy = true);
    final result = await _orchestrator.sendPasswordResetEmail();
    if (!mounted) return;
    setState(() => _busy = false);
    context.push('/auth/password-reset-result', extra: result);
  }

  Future<void> _updateJeno() async {
    setState(() => _busy = true);
    final result = await _orchestrator.createOrUpdateJeno(
      email: _jenoEmailController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    context.push('/auth/password-reset-result', extra: result);
  }

  @override
  Widget build(BuildContext context) {
    return PopScopeBackGuard(
      fallbackRoute: '/login/admin',
      child: Scaffold(
        backgroundColor: AppTheme.premiumBlack,
        appBar: AppBar(
          title: const Text('Récupération Admin Général'),
          backgroundColor: AppTheme.cardDark,
        ),
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.goldAccent),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const AppLogo(size: 72),
                    const SizedBox(height: 16),
                    Text(
                      AppConstants.appName,
                      style: authTextStyle(weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 20),
                    AuthFormCard(
                      accentColor: AppTheme.brandOrange,
                      compact: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            AppConstants.staffOwnerDisplayName,
                            style: authTextStyle(weight: FontWeight.w700),
                          ),
                          Text(
                            AdminRecoveryOrchestrator.ownerEmail,
                            style: authTextStyle(color: AppTheme.goldAccent),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Rôle : Responsable principal',
                            style: authTextStyle(color: AppTheme.textMuted),
                          ),
                          if (_status != null) ...[
                            const SizedBox(height: 12),
                            _StatusRow(
                              label: 'Synchronisation SQLite',
                              ok: _status!.existsLocally && _status!.isActiveLocally,
                            ),
                            _StatusRow(
                              label: 'Synchronisation Firebase',
                              ok: _status!.firebaseAvailable,
                            ),
                          ],
                          const SizedBox(height: 20),
                          _ActionButton(
                            label: 'Restaurer compte Verdick',
                            icon: Icons.healing_outlined,
                            busy: _busy,
                            onPressed: _busy ? null : _restore,
                          ),
                          const SizedBox(height: 10),
                          _ActionButton(
                            label: 'Envoyer lien de réinitialisation',
                            icon: Icons.mail_outline,
                            busy: _busy,
                            onPressed: _busy ? null : _sendResetLink,
                          ),
                          const Divider(height: 32),
                          Text(
                            'Jeno — Admin Général',
                            style: authTextStyle(weight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _jenoEmailController,
                            decoration: const InputDecoration(
                              labelText: 'Email de Jeno',
                              hintText: 'jeno@exemple.com',
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 12),
                          _ActionButton(
                            label: 'Créer / mettre à jour Jeno',
                            icon: Icons.person_add_outlined,
                            busy: _busy,
                            onPressed: _busy ? null : _updateJeno,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

typedef AdminRecoveryScreen = AdminOwnerRecoveryScreen;

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.ok});

  final String label;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle_outline : Icons.info_outline,
            size: 16,
            color: ok ? AppTheme.success : AppTheme.textMuted,
          ),
          const SizedBox(width: 8),
          Text(label, style: authTextStyle()),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.busy = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppTheme.brandOrange,
        minimumSize: const Size.fromHeight(46),
      ),
      icon: busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon),
      label: Text(
        label,
        style: authTextStyle(
          color: AppTheme.brandWhite,
          weight: FontWeight.w600,
        ),
      ),
    );
  }
}
