import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/bootstrap/app_startup_gate.dart';
import '../core/ui/global_loading_controller.dart';
import 'app.dart';
import 'theme.dart';

/// Point d'entrée unique — évite écran gris (une seule [MaterialApp] active à la fois).
class IfcmAppRoot extends ConsumerStatefulWidget {
  const IfcmAppRoot({super.key});

  @override
  ConsumerState<IfcmAppRoot> createState() => _IfcmAppRootState();
}

class _IfcmAppRootState extends ConsumerState<IfcmAppRoot> {
  bool _showMainApp = false;

  void _onBootstrapComplete({required bool offlineMode, String? notice}) {
    if (!mounted) return;
    ref.read(globalLoadingControllerProvider.notifier).hide();
    setState(() => _showMainApp = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_showMainApp) {
      return const IfcmApp();
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: AppStartupGate(
        onReady: _onBootstrapComplete,
        forceLaunchAfter: const Duration(seconds: 2),
      ),
    );
  }
}
