import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/constants.dart';
import '../../../app/theme.dart';
import '../../../core/auth/member_password_change_service.dart';
import '../../../core/auth/password_change_service.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/components/auth_ui_kit.dart';
import '../../../shared/models/member_account_model.dart';
/// Changement de mot de passe obligatoire — membre et admin staff.
class MandatoryPasswordChangeScreen extends ConsumerStatefulWidget {
  const MandatoryPasswordChangeScreen({super.key});

  @override
  ConsumerState<MandatoryPasswordChangeScreen> createState() =>
      _MandatoryPasswordChangeScreenState();
}

class _MandatoryPasswordChangeScreenState
    extends ConsumerState<MandatoryPasswordChangeScreen> {
  final _oldController = TextEditingController();
  final _confirmController = TextEditingController();
  final _newController = TextEditingController();
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String? _error;
  String _strengthMessage = '';

  @override
  void initState() {
    super.initState();
    _newController.addListener(_evaluateStrength);
  }

  void _evaluateStrength() {
    setState(() {
      _strengthMessage =
          PasswordStrength.evaluate(_newController.text).message;
    });
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final session = await ref.read(localSessionProvider.future);
      String? err;
      final passwordService = PasswordChangeService();

      if (session.isAdminAccount) {
        err = await passwordService.changeStaffPassword(
          accountId: session.userId!,
          oldPassword: _oldController.text,
          newPassword: _newController.text,
          confirmPassword: _confirmController.text,
        );
      } else {
        err = await passwordService.changeMemberPassword(
          account: MemberAccount(
            id: session.userId!,
            memberId: session.memberId ?? '',
            loginIdentifier: session.email ?? session.userId!,
            email: session.email,
          ),
          oldPassword: _oldController.text,
          newPassword: _newController.text,
          confirmPassword: _confirmController.text,
        );
      }

      if (err != null) {
        setState(() => _error = err);
        return;
      }

      await session.clearMustChangePassword();
      ref.invalidate(localSessionProvider);

      if (!mounted) return;
      if (session.isAdminAccount) {
        context.go('/dashboard');
      } else {
        context.go('/member/dashboard');
      }
    } catch (_) {
      setState(() => _error = 'Impossible de mettre à jour le mot de passe.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _oldController.dispose();
    _confirmController.dispose();
    _newController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.premiumBlack,
      appBar: AppBar(
        title: const Text('Changer mot de passe'),
        backgroundColor: AppTheme.cardDark,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AuthFormCard(
                accentColor: AppTheme.brandOrange,
                compact: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Nouveau mot de passe',
                      style: authTextStyle(weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Obligatoire à la première connexion',
                      style: authTextStyle(color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 16),
                    PasswordInputField(
                      controller: _oldController,
                      label: 'Mot de passe actuel (provisoire)',
                      obscure: _obscureOld,
                      onToggleVisibility: () =>
                          setState(() => _obscureOld = !_obscureOld),
                    ),
                    const SizedBox(height: 14),
                    PasswordInputField(
                      controller: _newController,
                      label: 'Nouveau mot de passe',
                      obscure: _obscureNew,
                      onToggleVisibility: () =>
                          setState(() => _obscureNew = !_obscureNew),
                    ),
                    if (_strengthMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _strengthMessage,
                          style: authTextStyle(
                            color: PasswordStrength.evaluate(_newController.text)
                                    .isValid
                                ? AppTheme.successProd
                                : AppTheme.warningProd,
                          ),
                        ),
                      ),
                    const SizedBox(height: 14),
                    PasswordInputField(
                      controller: _confirmController,
                      label: 'Confirmer le mot de passe',
                      obscure: _obscureConfirm,
                      onToggleVisibility: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: authTextStyle(color: AppTheme.danger)),
                    ],
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: _loading ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.brandOrange,
                        minimumSize: const Size.fromHeight(46),
                      ),
                      icon: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      label: Text(
                        'Enregistrer',
                        style: authTextStyle(
                          color: AppTheme.brandWhite,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
