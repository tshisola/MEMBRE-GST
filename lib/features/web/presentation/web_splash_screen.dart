import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../app/constants.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/app_logo.dart';

/// Splash Web professionnel — MEDIA LUBUMBASHI.
class WebSplashScreen extends StatelessWidget {
  const WebSplashScreen({super.key, this.onContinue});

  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.premiumBlack,
      child: Scaffold(
        backgroundColor: AppTheme.premiumBlack,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const AppLogo(size: 120, showTitle: true),
                    const SizedBox(height: 24),
                    Text(
                      AppConstants.appFullName,
                      style: const TextStyle(
                        color: AppTheme.goldAccent,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppConstants.organizationLegalLine,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textMuted.withValues(alpha: 0.9)),
                    ),
                    const SizedBox(height: 36),
                    const CircularProgressIndicator(color: AppTheme.brandOrange),
                    if (kIsWeb && onContinue != null) ...[
                      const SizedBox(height: 28),
                      FilledButton(
                        onPressed: onContinue,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.brandOrange,
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: const Text('Continuer'),
                      ),
                    ],
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
