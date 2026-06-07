import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../providers/app_providers.dart';
import 'web_reload.dart';
import 'web_version_checker.dart';

/// Bannière « Nouvelle version disponible » — Web uniquement.
class WebUpdateBanner extends ConsumerStatefulWidget {
  const WebUpdateBanner({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<WebUpdateBanner> createState() => _WebUpdateBannerState();
}

class _WebUpdateBannerState extends ConsumerState<WebUpdateBanner> {
  WebVersionCheckResult? _result;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) _check();
  }

  Future<void> _check() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final result = await WebVersionChecker().check(prefs: prefs);
    if (mounted) setState(() => _result = result);
  }

  Future<void> _update() async {
    final version = _result?.remoteVersion;
    if (version != null) {
      final prefs = await ref.read(sharedPreferencesProvider.future);
      await WebVersionChecker().markCurrentVersion(version, prefs);
    }
    if (kIsWeb) reloadWebApp();
  }

  @override
  Widget build(BuildContext context) {
    final show = kIsWeb && (_result?.updateAvailable ?? false);

    return Stack(
      children: [
        widget.child,
        if (show)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Material(
              color: AppTheme.brandBlue,
              elevation: 4,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.system_update, color: AppTheme.brandWhite),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Nouvelle version disponible',
                          style: TextStyle(color: AppTheme.brandWhite),
                        ),
                      ),
                      TextButton(
                        onPressed: _update,
                        child: const Text(
                          'Mettre à jour',
                          style: TextStyle(
                            color: AppTheme.brandWhite,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
