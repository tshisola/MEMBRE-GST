import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../../app/theme.dart';
import '../logging/technical_error_repository.dart';
import '../messaging/user_facing_messages.dart';
import 'app_logo.dart';

/// Full-screen loader — never a grey empty scaffold.
class AppLoadingScreen extends StatelessWidget {
  const AppLoadingScreen({
    super.key,
    this.message = 'Chargement…',
    this.subtitle,
  });

  final String message;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.premiumBlack,
      child: Scaffold(
        backgroundColor: AppTheme.premiumBlack,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const AppLogo(size: 88, showTitle: false),
                  const SizedBox(height: 28),
                  Text(
                    AppConstants.appFullName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.goldAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const ProfessionalLoader(),
                  const SizedBox(height: 20),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.brandWhite,
                      fontSize: 15,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      subtitle!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textSecondary.withValues(alpha: 0.9),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Professional circular loader (gold on black).
class ProfessionalLoader extends StatelessWidget {
  const ProfessionalLoader({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CircularProgressIndicator(
        strokeWidth: 2.5,
        color: AppTheme.goldAccent,
      ),
    );
  }
}

/// Écran d'information utilisateur — sans détails techniques (réservés au diagnostic Admin).
class AppErrorScreen extends StatelessWidget {
  AppErrorScreen({
    super.key,
    String? message,
    this.detail,
    this.onRetry,
    this.onLocalMode,
    this.onBackToLogin,
    this.onRepairDatabase,
    this.onContinueOnline,
    this.onDiagnostic,
    this.localModeLabel = 'Continuer',
    this.showTechnicalDetails = false,
    this.technicalError,
  }) : message = message ?? UserFacingMessages.genericIssue;

  final String message;
  final String? detail;
  final Object? technicalError;
  final bool showTechnicalDetails;
  final VoidCallback? onRetry;
  final VoidCallback? onLocalMode;
  final VoidCallback? onBackToLogin;
  final VoidCallback? onRepairDatabase;
  final VoidCallback? onContinueOnline;
  final VoidCallback? onDiagnostic;
  final String localModeLabel;

  @override
  Widget build(BuildContext context) {
    if (technicalError != null) {
      TechnicalErrorRepository.record(
        source: 'ui_error_screen',
        error: technicalError!,
      );
    }

    final userMessage = showTechnicalDetails
        ? message
        : TechnicalErrorRepository.sanitizeForUser(
            technicalError ?? detail ?? message,
            fallback: message,
          );
    final technicalDetail = showTechnicalDetails ? detail : null;

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
                  const AppLogo(size: 72, showTitle: false),
                  const SizedBox(height: 24),
                  Text(
                    UserFacingMessages.preparingTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.brandWhite,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    userMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.brandWhite,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  if (technicalDetail != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      technicalDetail,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textSecondary.withValues(alpha: 0.95),
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  if (onRetry != null)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: onRetry,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.brandOrange,
                          foregroundColor: AppTheme.brandWhite,
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: const Text('Réessayer'),
                      ),
                    ),
                  if (onContinueOnline != null) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: onContinueOnline,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.goldAccent,
                          side: const BorderSide(color: AppTheme.goldAccent),
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: Text(localModeLabel),
                      ),
                    ),
                  ] else if (onLocalMode != null) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: onLocalMode,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.goldAccent,
                          side: const BorderSide(color: AppTheme.goldAccent),
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: Text(localModeLabel),
                      ),
                    ),
                  ],
                  if (onDiagnostic != null) ...[
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: onDiagnostic,
                      icon: const Icon(Icons.medical_information_outlined,
                          color: AppTheme.goldLight),
                      label: const Text(
                        'Diagnostic',
                        style: TextStyle(color: AppTheme.goldLight),
                      ),
                    ),
                  ],
                  if (onBackToLogin != null) ...[
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: onBackToLogin,
                      child: const Text(
                        'Retour au choix de connexion',
                        style: TextStyle(color: AppTheme.goldLight),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Empty list / data placeholder.
class EmptyStateScreen extends StatelessWidget {
  const EmptyStateScreen({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.brandWhite,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.brandOrange,
                  foregroundColor: AppTheme.brandWhite,
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Fallback when GoRouter child is null during transitions.
class AppShellFallback extends StatelessWidget {
  const AppShellFallback({super.key, this.authOnly = false});

  final bool authOnly;

  /// Sur les écrans d'auth : fond noir seul — pas de loader bloquant.
  factory AppShellFallback.forPath(String path) {
    final isAuth = path == '/' ||
        path == '/login' ||
        path.startsWith('/login/') ||
        path.startsWith('/auth/');
    return AppShellFallback(authOnly: isAuth);
  }

  @override
  Widget build(BuildContext context) {
    if (authOnly) {
      return const ColoredBox(
        color: AppTheme.premiumBlack,
        child: SizedBox.expand(),
      );
    }
    return const AppLoadingScreen(
      message: 'Préparation de l\'interface…',
      subtitle: 'Veuillez patienter',
    );
  }
}

/// Bouton réessayer standard.
class ErrorRetryButton extends StatelessWidget {
  const ErrorRetryButton({super.key, required this.onRetry, this.label = 'Réessayer'});

  final VoidCallback onRetry;
  final String label;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onRetry,
      style: FilledButton.styleFrom(
        backgroundColor: AppTheme.brandOrange,
        foregroundColor: AppTheme.brandWhite,
      ),
      icon: const Icon(Icons.refresh),
      label: Text(label),
    );
  }
}

/// Bouton mode local (Firebase indisponible).
class LocalModeButton extends StatelessWidget {
  const LocalModeButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.brandBlue,
        side: const BorderSide(color: AppTheme.brandBlue),
      ),
      icon: const Icon(Icons.storage),
      label: const Text('Mode local'),
    );
  }
}
