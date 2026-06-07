import 'package:flutter/material.dart';

import '../../../app/constants.dart';
import '../../../app/theme.dart';
import '../../../core/messaging/user_facing_messages.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/app_shell_screens.dart';

/// Écran de patience professionnel — aucun détail technique.
class AppRecoveryScreen extends StatelessWidget {
  const AppRecoveryScreen({
    super.key,
    this.onRetry,
    this.onContinue,
    this.showLoader = true,
  });

  final VoidCallback? onRetry;
  final VoidCallback? onContinue;
  final bool showLoader;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.premiumBlack,
      child: Scaffold(
        backgroundColor: AppTheme.premiumBlack,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const AppLogo(size: 96, showTitle: true),
                  const SizedBox(height: 28),
                  Text(
                    UserFacingMessages.preparingTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.brandWhite,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    UserFacingMessages.preparingContinue,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textSecondary.withValues(alpha: 0.95),
                      fontSize: 15,
                      height: 1.45,
                    ),
                  ),
                  if (showLoader) ...[
                    const SizedBox(height: 32),
                    const ProfessionalLoader(),
                  ],
                  const SizedBox(height: 32),
                  if (onContinue != null)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: onContinue,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.brandOrange,
                          foregroundColor: AppTheme.brandWhite,
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: const Text('Continuer'),
                      ),
                    ),
                  if (onRetry != null) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: onRetry,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.brandBlue,
                          side: const BorderSide(color: AppTheme.brandBlue),
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: const Text('Réessayer'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    AppConstants.organizationLegalLine,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
