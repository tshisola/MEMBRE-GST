import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/constants.dart';
import '../../../app/theme.dart';
import '../../../core/bootstrap/app_initializer.dart';
import '../../../core/firebase/firebase_initializer.dart';
import '../../../core/logging/error_reporter_local.dart';
import '../../../core/logging/technical_error_repository.dart';
import '../../../core/database/database_health_checker.dart';
import '../../../core/database/database_repair_service.dart';
import '../../../core/production/app_health_checker.dart';
import 'database_repair_screen.dart';
import '../../../core/production/auto_repair_service.dart';
import '../../../core/bootstrap/local_mode_service.dart';
import '../../../core/auth/staff_firebase_provisioning_service.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/background_sync_providers.dart';
import '../../../core/sync/auto_sync_manager.dart';
import '../../../core/ui/global_loading_controller.dart';
import '../../../core/ui/startup_loading_guard.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/app_shell_screens.dart';
import '../../../shared/components/pop_scope_back_guard.dart';
import '../../../shared/components/screen_header.dart';

/// Admin — diagnostic production (erreurs, sync, SQLite, auto-réparation).
class AppDiagnosticScreen extends ConsumerStatefulWidget {
  const AppDiagnosticScreen({super.key});

  @override
  ConsumerState<AppDiagnosticScreen> createState() => _AppDiagnosticScreenState();
}

class _AppDiagnosticScreenState extends ConsumerState<AppDiagnosticScreen> {
  List<DiagnosticLogEntry> _logs = [];
  AppHealthReport? _health;
  DatabaseHealthReport? _sqliteHealth;
  String? _lastRoute;
  bool _loading = true;
  bool _repairing = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final logs = await ErrorReporterLocal.loadEntries();
    final route = await ErrorReporterLocal.getLastRoute();
    final health = await AppHealthChecker.check();
    final sqliteHealth = await DatabaseHealthChecker.check();
    if (mounted) {
      setState(() {
        _logs = logs;
        _lastRoute = route;
        _health = health;
        _sqliteHealth = sqliteHealth;
        _loading = false;
      });
    }
  }

  Future<void> _clearLogs() async {
    await ErrorReporterLocal.clear();
    await _reload();
  }

  Future<void> _retrySync() async {
    await ref.read(autoSyncManagerProvider).runBackgroundSync(
          trigger: 'diagnostic',
          forcePull: true,
        );
    await AppInitializer.runDeferredSync();
    await _reload();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Synchronisation relancée')),
      );
    }
  }

  Future<void> _repairSqlite() async {
    setState(() => _repairing = true);
    final result = await DatabaseRepairService.repair();
    await _reload();
    if (mounted) {
      setState(() => _repairing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    }
  }

  Future<void> _autoRepair() async {
    setState(() => _repairing = true);
    final result = await AutoRepairService().run();
    await _reload();
    if (mounted) {
      setState(() => _repairing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    }
  }

  Future<void> _provisionStaffFirebase() async {
    setState(() => _repairing = true);
    final result =
        await StaffFirebaseProvisioningService().provisionAllIfNeeded();
    await _reload();
    if (mounted) {
      setState(() => _repairing = false);
      final String msg;
      if (result.emailPasswordDisabled) {
        msg =
            'Activez « Email/Mot de passe » dans Firebase Auth (gratuit, 1 clic). '
            'Puis reconnectez-vous ou relancez le provisioning.';
      } else if (result.allProvisioned) {
        msg =
            'Comptes Firebase staff OK (${result.created} créés, ${result.linked} liés) — plan gratuit.';
      } else {
        msg = 'Provisioning partiel — chaque staff peut aussi se connecter une fois en ligne.';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _enableLocalMode() async {
    await LocalModeService.enableLocalMode();
    await _reload();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mode local activé')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(backgroundSyncStateProvider);
    final globalLoading = ref.watch(globalLoadingControllerProvider);
    final currentPath = GoRouter.of(context).state.uri.path;
    final firebaseOk = FirebaseInitializer.isInitialized;
    final health = _health;
    final lastSync = ref.read(memberSyncManagerProvider).lastSyncAt;
    final lastSyncLabel = lastSync != null
        ? '${lastSync.toLocal().toString().substring(0, 16)}'
        : 'Jamais';

    return PopScopeBackGuard(
      fallbackRoute: '/dashboard',
      child: Scaffold(
      backgroundColor: AppTheme.premiumBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.premiumBlack,
        leading: const AppBackButton(fallbackRoute: '/dashboard'),
        title: const Text('Diagnostic application'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _reload),
        ],
      ),
      body: _loading
          ? const AppLoadingScreen(message: 'Analyse en cours…')
          : ListView(
              padding: EdgeInsets.zero,
              children: [
                ScreenHeader(
                  title: 'État système',
                  subtitle: 'Production · ${AppConstants.appName}',
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _InfoTile(
                        label: 'Firebase',
                        value: firebaseOk ? 'Connecté' : 'Hors ligne',
                        color: firebaseOk ? AppTheme.successProd : AppTheme.warningProd,
                      ),
                      _InfoTile(
                        label: 'SQLite',
                        value: health?.sqliteOpen == true ? 'Ouvert' : 'Erreur',
                        color: health?.sqliteOpen == true
                            ? AppTheme.successProd
                            : AppTheme.errorProd,
                      ),
                      _InfoTile(
                        label: 'Membres locaux',
                        value: '${health?.memberCount ?? 0}',
                        color: AppTheme.brandBlue,
                      ),
                      _InfoTile(
                        label: 'File sync (v4)',
                        value: '${health?.pendingSyncQueue ?? 0} en attente',
                        color: AppTheme.warningProd,
                      ),
                      _InfoTile(
                        label: 'File legacy',
                        value: '${health?.pendingLegacyQueue ?? 0} en attente',
                        color: AppTheme.textMuted,
                      ),
                      _InfoTile(
                        label: 'Dernière synchronisation',
                        value: lastSyncLabel,
                        color: AppTheme.successProd,
                      ),
                      _InfoTile(
                        label: 'Phase sync',
                        value: syncState.phase.name,
                        color: AppTheme.info,
                      ),
                      _InfoTile(
                        label: 'Dernière route',
                        value: _lastRoute ?? '—',
                        color: AppTheme.textMuted,
                      ),
                      _InfoTile(
                        label: 'Route actuelle',
                        value: currentPath,
                        color: AppTheme.brandBlue,
                      ),
                      _InfoTile(
                        label: 'Overlay global actif',
                        value: globalLoading.isVisible ? 'Oui' : 'Non',
                        color: globalLoading.isVisible
                            ? AppTheme.warningProd
                            : AppTheme.successProd,
                      ),
                      _InfoTile(
                        label: 'État loading global',
                        value: globalLoading.reason ?? 'idle',
                        color: AppTheme.textMuted,
                      ),
                      _InfoTile(
                        label: 'Bootstrap gate terminé',
                        value: StartupUiFlags.bootstrapGateCompleted ? 'Oui' : 'Non',
                        color: AppTheme.textMuted,
                      ),
                      _InfoTile(
                        label: 'Sync en cours',
                        value: syncState.phase == BackgroundSyncPhase.syncing
                            ? 'Oui'
                            : 'Non',
                        color: syncState.phase == BackgroundSyncPhase.syncing
                            ? AppTheme.warningProd
                            : AppTheme.successProd,
                      ),
                      if (TechnicalErrorRepository.last != null)
                        _InfoTile(
                          label: 'Dernière erreur technique',
                          value: TechnicalErrorRepository.last!.message,
                          color: AppTheme.errorProd,
                        ),
                      if (health?.dbPath != null)
                        _InfoTile(
                          label: 'Base SQLite',
                          value: health!.dbPath!,
                          color: AppTheme.textMuted,
                        ),
                      const SizedBox(height: 16),
                      Card(
                        color: AppTheme.cardSecondary,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mises à jour sans APK',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.brandOrange,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Cloud : données, rôles, permissions, textes, couleurs, '
                                'menus SDUI, feature flags, rules, functions, Web Hosting.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Nouvel APK requis : plugin natif, permission Android, '
                                'écran non prévu par le renderer dynamique, changement code profond.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_sqliteHealth != null) ...[
                        _InfoTile(
                          label: 'Taille base',
                          value: _sqliteHealth!.fileSizeBytes != null
                              ? '${(_sqliteHealth!.fileSizeBytes! / 1024).toStringAsFixed(1)} Ko'
                              : '—',
                          color: AppTheme.textMuted,
                        ),
                        _InfoTile(
                          label: 'Temps ouverture SQLite',
                          value: _sqliteHealth!.openDurationMs != null
                              ? '${_sqliteHealth!.openDurationMs} ms'
                              : '—',
                          color: AppTheme.textMuted,
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _repairing ? null : _autoRepair,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppTheme.brandOrange,
                              ),
                              icon: _repairing
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.build_circle_outlined),
                              label: const Text('Corriger auto'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _retrySync,
                              icon: const Icon(Icons.sync),
                              label: const Text('Relancer sync'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _repairing ? null : _provisionStaffFirebase,
                        icon: const Icon(Icons.admin_panel_settings_outlined),
                        label: const Text('Provisionner comptes Firebase staff'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _repairing ? null : _repairSqlite,
                        icon: const Icon(Icons.storage),
                        label: const Text('Réparer SQLite'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const DatabaseRepairScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.medical_information_outlined),
                        label: const Text('Écran réparation complet'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _clearLogs,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Effacer logs'),
                      ),
                      const SizedBox(height: 8),
                      LocalModeButton(onPressed: _enableLocalMode),
                      const SizedBox(height: 24),
                      Text(
                        'Journal des erreurs (${_logs.length})',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.brandWhite,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_logs.isEmpty)
                        const Text(
                          'Aucune erreur enregistrée.',
                          style: TextStyle(color: AppTheme.textMuted),
                        )
                      else
                        ..._logs.take(40).map(_LogCard.new),
                    ],
                  ),
                ),
              ],
            ),
    ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.cardDark,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        title: Text(label, style: const TextStyle(fontSize: 12)),
        subtitle: Text(
          value,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
    );
  }
}

class _LogCard extends StatelessWidget {
  const _LogCard(this.entry);

  final DiagnosticLogEntry entry;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.cardSecondary,
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(
          '[${entry.category}] ${entry.message}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),
        subtitle: Text(
          entry.at.toIso8601String(),
          style: const TextStyle(fontSize: 10),
        ),
        children: [
          if (entry.stackTrace != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: SelectableText(
                entry.stackTrace!,
                style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
              ),
            ),
        ],
      ),
    );
  }
}
