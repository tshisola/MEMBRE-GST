import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/auth/logout_service.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/app_logo.dart';

class ActivationRejectedScreen extends ConsumerWidget {
  const ActivationRejectedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.premiumBlack,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppLogo(size: 72, showTitle: false),
              const SizedBox(height: 24),
              const Text(
                'Demande non approuvée',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.brandWhite,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Votre demande d\'accès n\'a pas été approuvée. Contactez l\'administrateur pour plus d\'informations.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.brandWhite, height: 1.4),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () async {
                  await ref.read(logoutServiceProvider).logout(ref);
                  if (context.mounted) context.go('/login/member');
                },
                child: const Text('Retour connexion'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
