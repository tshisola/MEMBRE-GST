import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'global_loading_controller.dart';
import 'loading_timeout_service.dart';

/// Coupe tout loader global après le démarrage — LoginChoice reste cliquable.
class StartupLoadingGuard extends ConsumerStatefulWidget {
  const StartupLoadingGuard({super.key});

  @override
  ConsumerState<StartupLoadingGuard> createState() => _StartupLoadingGuardState();
}

class _StartupLoadingGuardState extends ConsumerState<StartupLoadingGuard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(globalLoadingControllerProvider.notifier).hide();
    });
    _timer = LoadingTimeoutService.schedule(
      duration: LoadingTimeoutService.startupMaxBlocking,
      onTimeout: () {
        if (mounted) {
          ref.read(globalLoadingControllerProvider.notifier).hide();
        }
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Indique que le bootstrap gate a terminé — le splash route peut sauter.
class StartupUiFlags {
  StartupUiFlags._();

  static bool bootstrapGateCompleted = false;
}
