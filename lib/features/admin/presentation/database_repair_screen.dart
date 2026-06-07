import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/database/database_health_checker.dart';
import '../../../core/database/database_manager.dart';
import '../../../core/database/database_repair_service.dart';
import '../../../core/sync/cloud_only_fallback_service.dart';
import '../../../shared/components/screen_header.dart';

/// Réparation SQLite — accessible au démarrage ou depuis Diagnostic Admin.
class DatabaseRepairScreen extends StatefulWidget {
  const DatabaseRepairScreen({super.key});

  @override
  State<DatabaseRepairScreen> createState() => _DatabaseRepairScreenState();
}

class _DatabaseRepairScreenState extends State<DatabaseRepairScreen> {
  DatabaseHealthReport? _report;
  bool _loading = true;
  bool _working = false;
  String? _lastMessage;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final report = await DatabaseHealthChecker.check();
    if (mounted) {
      setState(() {
        _report = report;
        _loading = false;
      });
    }
  }

  Future<void> _repair() async {
    setState(() => _working = true);
    final result = await DatabaseRepairService.repair();
    await _reload();
    if (mounted) {
      setState(() {
        _working = false;
        _lastMessage = result.message;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    }
  }

  Future<void> _continueOnline() async {
    final ok = await CloudOnlyFallbackService.canUse();
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Firebase indisponible — vérifiez votre connexion.'),
        ),
      );
      return;
    }
    await CloudOnlyFallbackService.enable();
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mode en ligne temporaire activé')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;
    final manager = DatabaseManager.instance;

    return Scaffold(
      backgroundColor: AppTheme.premiumBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.premiumBlack,
        title: const Text('Réparation base locale'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const ScreenHeader(
                  title: 'SQLite — IFCM Lubumbashi',
                  subtitle:
                      'Aucune donnée n\'est supprimée sans confirmation Admin Général.',
                ),
                if (_lastMessage != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(_lastMessage!),
                    ),
                  ),
                _InfoTile('Statut', manager.status.name),
                _InfoTile('Chemin', report?.path ?? '—'),
                _InfoTile(
                  'Taille',
                  report?.fileSizeBytes != null
                      ? '${(report!.fileSizeBytes! / 1024).toStringAsFixed(1)} Ko'
                      : '—',
                ),
                _InfoTile('Tables', '${report?.tableCount ?? 0}'),
                _InfoTile(
                  'Ouverture',
                  manager.openDurationMs != null
                      ? '${manager.openDurationMs} ms'
                      : '—',
                ),
                if (manager.lastError != null)
                  _InfoTile('Dernière erreur', manager.lastError!),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _working ? null : _reload,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: _working ? null : _repair,
                  icon: _working
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.build),
                  label: const Text('Réparer la base locale'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.brandBlue,
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _continueOnline,
                  icon: const Icon(Icons.cloud),
                  label: const Text('Continuer en ligne'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => _showDiagnostic(context, report),
                  icon: const Icon(Icons.info_outline),
                  label: const Text('Diagnostic détaillé'),
                ),
              ],
            ),
    );
  }

  void _showDiagnostic(BuildContext context, DatabaseHealthReport? report) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Diagnostic SQLite'),
        content: SingleChildScrollView(
          child: Text(
            [
              'Fichier: ${report?.fileExists ?? false}',
              'Ouvert: ${report?.isOpen ?? false}',
              'Migrations récentes: ${report?.recentMigrations.length ?? 0}',
              if (report?.recentMigrations.isNotEmpty == true)
                report!.recentMigrations
                    .map((m) => '${m['migration_name']}: ${m['status']}')
                    .join('\n'),
            ].join('\n'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontSize: 12)),
      subtitle: Text(value, style: const TextStyle(fontSize: 14)),
    );
  }
}
