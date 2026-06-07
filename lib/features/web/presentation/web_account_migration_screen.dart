import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/constants.dart';
import '../../../app/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/web/web_access_migration_service.dart';
import '../../../shared/components/auth_ui_kit.dart';

/// Active l'accès Web pour les comptes existants — Owner / Jeno autorisé.
class WebAccountMigrationScreen extends ConsumerStatefulWidget {
  const WebAccountMigrationScreen({super.key});

  @override
  ConsumerState<WebAccountMigrationScreen> createState() =>
      _WebAccountMigrationScreenState();
}

class _WebAccountMigrationScreenState
    extends ConsumerState<WebAccountMigrationScreen> {
  final _service = EnableWebAccessForExistingAccountsService();
  final _guard = const WebAccessMigrationGuard();
  bool _running = false;
  WebAccessMigrationResult? _result;

  Future<void> _run() async {
    final session = await ref.read(localSessionProvider.future);
    if (!_guard.canRun(
      role: session.role,
      permissions: session.permissions,
    )) {
      _toast('Accès non autorisé.');
      return;
    }

    setState(() {
      _running = true;
      _result = null;
    });

    final result = await _service.migrateAll();
    if (mounted) {
      setState(() {
        _running = false;
        _result = result;
      });
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.cardSecondary),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.premiumBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.cardDark,
        title: Text('Accès Web', style: authTextStyle(weight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WebAccessMigrationCard(
              running: _running,
              result: _result,
              onRun: _run,
            ),
          ],
        ),
      ),
    );
  }
}

class WebAccessMigrationCard extends StatelessWidget {
  const WebAccessMigrationCard({
    super.key,
    required this.running,
    required this.onRun,
    this.result,
  });

  final bool running;
  final VoidCallback onRun;
  final WebAccessMigrationResult? result;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activer accès Web pour les comptes existants',
            style: authTextStyle(weight: FontWeight.w700, color: AppTheme.brandWhite),
          ),
          const SizedBox(height: 10),
          Text(
            'Ajoute la permission d\'accès Web selon le rôle existant, '
            'sans modifier les mots de passe ni créer de doublons.',
            style: authTextStyle(color: AppTheme.textMuted),
          ),
          if (result != null) ...[
            const SizedBox(height: 16),
            Text(
              result!.message ?? 'Opération terminée.',
              style: authTextStyle(
                color: result!.success ? AppTheme.success : AppTheme.danger,
              ),
            ),
            if (result!.updated > 0)
              Text(
                '${result!.updated} mis à jour · ${result!.skipped} ignorés',
                style: authTextStyle(color: AppTheme.textMuted),
              ),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: running ? null : onRun,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.brandOrange,
              minimumSize: const Size.fromHeight(48),
            ),
            icon: running
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.brandWhite,
                    ),
                  )
                : const Icon(Icons.language),
            label: const Text('Lancer la migration Web'),
          ),
        ],
      ),
    );
  }
}
