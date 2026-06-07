import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../../app/theme.dart';
import '../messaging/user_facing_messages.dart';
import '../widgets/app_logo.dart';
import '../widgets/app_shell_screens.dart';
import '../firebase/firebase_initializer.dart';
import '../sync/cloud_only_fallback_service.dart';
import 'app_initializer.dart';
import 'app_startup_service.dart';
import '../ui/startup_loading_guard.dart';
import 'silent_startup_recovery_service.dart';

/// Lance l'UI en ≤ 2 s — jamais d'erreur technique affichée.
class AppStartupGate extends StatefulWidget {
  const AppStartupGate({
    super.key,
    required this.onReady,
    this.forceLaunchAfter = const Duration(seconds: 2),
  });

  final void Function({required bool offlineMode, String? notice}) onReady;
  final Duration forceLaunchAfter;

  @override
  State<AppStartupGate> createState() => _AppStartupGateState();
}

class _AppStartupGateState extends State<AppStartupGate> {
  late Future<StartupState> _bootstrapFuture;
  bool _launched = false;
  Timer? _forceTimer;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = AppStartupService.bootstrap();
    _forceTimer = Timer(widget.forceLaunchAfter, _forceLaunchUi);
  }

  @override
  void dispose() {
    _forceTimer?.cancel();
    super.dispose();
  }

  void _forceLaunchUi() {
    if (_launched || !mounted) return;
    _launch(
      const StartupState(
        phase: StartupPhase.degraded,
        result: AppInitResult(
          databaseReady: false,
          sqlitePending: true,
          allowUiLaunch: true,
          firebaseResult: FirebaseInitResult(success: false),
        ),
      ),
    );
  }

  void _launch(StartupState state) {
    if (_launched) return;
    _launched = true;
    _forceTimer?.cancel();

    StartupUiFlags.bootstrapGateCompleted = true;
    SilentStartupRecoveryService.start();

    final result = state.result;
    final offline = state.phase == StartupPhase.offlineMode ||
        !(result?.firebaseReady ?? false);

    String? notice;
    if (state.phase == StartupPhase.degraded ||
        result?.sqlitePending == true) {
      notice = UserFacingMessages.backgroundPrep;
    } else if (offline) {
      notice = UserFacingMessages.offlineHint;
    }

    widget.onReady(offlineMode: offline, notice: notice);
  }

  void _retry() {
    setState(() {
      _launched = false;
      _bootstrapFuture = AppStartupService.bootstrap();
      _forceTimer?.cancel();
      _forceTimer = Timer(widget.forceLaunchAfter, _forceLaunchUi);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StartupState>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData &&
            !_launched) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _launch(snapshot.data!),
          );
        }

        if (_launched) {
          return const SizedBox.shrink();
        }

        return _BootstrapSplashPage(
          onRetry: _retry,
          onContinue: _forceLaunchUi,
          showActions: snapshot.connectionState == ConnectionState.done,
        );
      },
    );
  }
}

class _BootstrapSplashPage extends StatelessWidget {
  const _BootstrapSplashPage({
    required this.onRetry,
    required this.onContinue,
    this.showActions = false,
  });

  final VoidCallback onRetry;
  final VoidCallback onContinue;
  final bool showActions;

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
                  const AppLogo(size: 110, showTitle: true),
                  const SizedBox(height: 24),
                  Text(
                    UserFacingMessages.preparingTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.brandWhite,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    UserFacingMessages.preparingBody,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textSecondary.withValues(alpha: 0.95),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 36),
                  const ProfessionalLoader(),
                  if (showActions) ...[
                    const SizedBox(height: 28),
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
                  const SizedBox(height: 12),
                  Text(
                    AppConstants.organizationLegalLine,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary.withValues(alpha: 0.65),
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
