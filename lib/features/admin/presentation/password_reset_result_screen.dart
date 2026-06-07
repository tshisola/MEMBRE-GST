import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/auth/admin_recovery_orchestrator.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../shared/components/auth_ui_kit.dart';
import '../../../shared/components/pop_scope_back_guard.dart';

/// Résultat réinitialisation — message professionnel uniquement.
class PasswordResetResultScreen extends StatelessWidget {
  const PasswordResetResultScreen({super.key, required this.result});

  final AdminRecoveryResult result;

  @override
  Widget build(BuildContext context) {
    return PopScopeBackGuard(
      fallbackRoute: '/login/admin',
      child: Scaffold(
        backgroundColor: AppTheme.premiumBlack,
        appBar: AppBar(
          leading: const AppBackButton(fallbackRoute: '/login/admin'),
          title: const Text('Résultat'),
          backgroundColor: AppTheme.cardDark,
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                result.success ? Icons.check_circle_outline : Icons.info_outline,
                size: 56,
                color: result.success ? AppTheme.success : AppTheme.warningProd,
              ),
              const SizedBox(height: 16),
              Text(
                result.message,
                style: authTextStyle(weight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              if (result.temporaryPassword != null) ...[
                const SizedBox(height: 20),
                Text(
                  'Mot de passe provisoire (affichage unique)',
                  style: authTextStyle(color: AppTheme.textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                SelectableText(
                  result.temporaryPassword!,
                  style: authTextStyle(
                    color: AppTheme.goldLight,
                    weight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (result.success) ...[
                const SizedBox(height: 16),
                Text(
                  result.temporaryPassword != null
                      ? 'Un changement de mot de passe sera demandé à la prochaine connexion.'
                      : 'Action terminée.',
                  style: authTextStyle(color: AppTheme.textMuted),
                  textAlign: TextAlign.center,
                ),
              ],
              const Spacer(),
              FilledButton(
                onPressed: () => context.go('/login/admin'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.brandOrange,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Retour à la connexion'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
