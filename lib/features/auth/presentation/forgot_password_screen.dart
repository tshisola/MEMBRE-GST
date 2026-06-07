import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../shared/components/auth_ui_kit.dart';

/// Mot de passe oublié — oriente vers le responsable IFCM.
class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mot de passe oublié'),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: ProfessionalAuthCard(
                title: 'Réinitialisation',
                subtitle: 'Contactez votre responsable IFCM',
                icon: Icons.help_outline,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Pour des raisons de sécurité, la réinitialisation du mot de passe '
                      'doit être effectuée par un Admin ou responsable de département '
                      'directement dans l\'application IFCM.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    ProfessionalActionButton(
                      label: 'Retour connexion',
                      icon: Icons.arrow_back,
                      onPressed: () => context.pop(),
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
