import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:go_router/go_router.dart';

import '../../../app/constants.dart';
import '../../../app/theme.dart';
import '../../../core/firebase/firebase_initializer.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/sync/auth_sync_services.dart';
import '../../../core/remote/sync_all_cloud_config_service.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../shared/components/app_drawer.dart';
import '../../../shared/components/pop_scope_back_guard.dart';
import '../../../features/admin_realtime/presentation/members_live_provider.dart';
import '../../../core/providers/background_sync_providers.dart';
import '../../../features/members/presentation/member_conflict_screen.dart';
import '../../../core/bootstrap/background_sync_host.dart';
import '../../../shared/components/member_sync_ui_kit.dart';
import '../../../shared/components/premium_ui_kit.dart';
import '../../../shared/components/screen_header.dart';

class AdminSyncScreen extends ConsumerStatefulWidget {
  const AdminSyncScreen({super.key});

  @override
  ConsumerState<AdminSyncScreen> createState() => _AdminSyncScreenState();
}

class _AdminSyncScreenState extends ConsumerState<AdminSyncScreen> {
  DateTime? _lastSync;
  int _pendingItems = 0;
  String? _syncMessage;
  bool _syncAllLoading = false;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    final syncManager = ref.read(syncManagerProvider);
    final status = await syncManager.getStatus();
    final memberLastSync = ref.read(memberSyncManagerProvider).lastSyncAt;
    if (mounted) {
      setState(() {
        _pendingItems = status.pendingCount + status.failedCount;
        _syncMessage = status.hasErrors
            ? 'Synchronisation en attente. Les données seront mises à jour automatiquement.'
            : null;
        if (memberLastSync != null) _lastSync = memberLastSync;
      });
    }
  }

  Future<void> _syncAllSystem() async {
    final session = await ref.read(localSessionProvider.future);
    final cloudSync = SyncAllCloudConfigService();
    if (!cloudSync.canRun(role: session.role)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Action réservée au responsable principal.')),
        );
      }
      return;
    }

    setState(() => _syncAllLoading = true);
    try {
      final result = await cloudSync.syncAll(role: session.role);
      if (result.success) {
        await _forceSync(showSnackBar: false);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.success
                  ? (result.message ?? 'Synchronisation terminée avec succès.')
                  : (result.message ?? 'Veuillez réessayer.'),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _syncAllLoading = false);
    }
  }

  Future<void> _forceSync({bool showSnackBar = true}) async {
    final syncState = ref.read(syncStatusProvider.notifier);
    await syncState.syncAll();
    await ref.read(autoSyncManagerProvider).runBackgroundSync(
          trigger: 'admin_force',
          forcePull: true,
        );
    await ref.read(mediaSyncServiceProvider).fullSync();
    await ref.read(syncManagerProvider).flushQueue();

    if (mounted) {
      setState(() {
        _lastSync = ref.read(memberSyncManagerProvider).lastSyncAt ?? DateTime.now();
        _pendingItems = ref.read(syncStatusProvider).pendingCount;
        _syncMessage = ref.read(syncStatusProvider).lastMessage;
      });
      if (showSnackBar) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              FirebaseInitializer.isInitialized
                  ? 'Synchronisation terminée — comptes, listes et média'
                  : 'Données mises en file d\'attente (hors ligne)',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = FirebaseInitializer.isInitialized;
    final syncStatus = ref.watch(syncStatusProvider);
    final syncState = ref.watch(backgroundSyncStateProvider);
    final memberSummaryAsync = ref.watch(memberSyncSummaryProvider);
    final memberSummary = memberSummaryAsync.valueOrNull;
    final conflictsAsync = ref.watch(unresolvedConflictsCountProvider);
    final conflictCount = conflictsAsync.valueOrNull ?? 0;
    final sessionAsync = ref.watch(localSessionProvider);
    final isOwner = sessionAsync.valueOrNull?.role ==
        AppConstants.roleAdminGeneralOwner;
    final lastSyncLabel = _lastSync != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(_lastSync!)
        : 'Jamais';
    final pending = _pendingItems > 0 ? _pendingItems : syncStatus.pendingCount;

    return PopScopeBackGuard(
      fallbackRoute: '/dashboard',
      child: Scaffold(
      backgroundColor: AppTheme.premiumBlack,
      drawer: const AppDrawer(currentRoute: '/admin/sync'),
      appBar: AppBar(
        backgroundColor: AppTheme.cardDark,
        leading: const AppBackButton(fallbackRoute: '/dashboard'),
        title: const Text('Synchronisation'),
        actions: [
          RefreshButton(
            compact: true,
            onRefresh: () async {
              final r = await ref.read(manualSyncRefreshServiceProvider).refresh();
              bumpMembersRevision(ref);
              await _refreshStatus();
              return r.message;
            },
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          ScreenHeader(
            title: 'Sync Firebase',
            subtitle: 'Temps réel · ${AppConstants.city}',
            showFirebaseIndicator: true,
            isFirebaseConnected: isConnected,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(
                          isConnected ? Icons.cloud_done : Icons.cloud_off,
                          size: 64,
                          color: isConnected ? AppTheme.success : AppTheme.danger,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isConnected ? 'Connecté à Firebase' : 'Mode hors ligne',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        FirebaseConnectionIndicator(isConnected: isConnected),
                        if (_syncMessage != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _syncMessage!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.info,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                AdminSyncControlCard(
                  state: syncState,
                  onForceSync: _forceSync,
                  isLoading: syncStatus.isSyncing,
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    StatCard(
                      label: 'Dernière sync',
                      value: lastSyncLabel.split(' ').first,
                      icon: Icons.access_time,
                    ),
                    StatCard(
                      label: 'En attente',
                      value: '${pending + (memberSummary?.pending ?? 0)}',
                      icon: Icons.pending_actions,
                      color: pending > 0 ? AppTheme.goldAccent : AppTheme.success,
                    ),
                    if (memberSummary != null)
                      StatCard(
                        label: 'Membres sync',
                        value: '${memberSummary.synced}',
                        icon: Icons.groups,
                        color: AppTheme.success,
                      ),
                    if (memberSummary != null && memberSummary.errors > 0)
                      StatCard(
                        label: 'Erreurs membres',
                        value: '${memberSummary.errors}',
                        icon: Icons.error_outline,
                        color: AppTheme.danger,
                      ),
                    if (conflictCount > 0)
                      StatCard(
                        label: 'Conflits sync',
                        value: '$conflictCount',
                        icon: Icons.merge_type,
                        color: const Color(0xFFCE93D8),
                      ),
                  ],
                ),
                if (conflictCount > 0) ...[
                  const SizedBox(height: 12),
                  Card(
                    color: const Color(0xFFCE93D8).withValues(alpha: 0.12),
                    child: ListTile(
                      leading: const Icon(Icons.merge_type, color: Color(0xFFCE93D8)),
                      title: Text('$conflictCount conflit(s) à résoudre'),
                      subtitle: const Text('Local vs Firebase — revue Admin Général'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => context.push('/admin/sync/conflicts'),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                const SectionHeader(
                  title: 'Collections synchronisées',
                  subtitle: 'Données ${AppConstants.appName}',
                ),
                _SyncCollectionTile(
                  name: 'Membres IFCM (members)',
                  icon: Icons.groups_outlined,
                  synced: isConnected && (memberSummary?.errors ?? 0) == 0,
                ),
                _SyncCollectionTile(
                  name: 'QR Codes (memberQrCodes)',
                  icon: Icons.qr_code_2,
                  synced: isConnected,
                ),
                _SyncCollectionTile(
                  name: 'Pointage (media_attendance)',
                  icon: Icons.fact_check_outlined,
                  synced: isConnected,
                ),
                _SyncCollectionTile(
                  name: 'Listes Média (media_lists)',
                  icon: Icons.list_alt,
                  synced: isConnected,
                ),
                _SyncCollectionTile(
                  name: 'Comptes membres (memberAccounts)',
                  icon: Icons.people_outline,
                  synced: isConnected,
                ),
                _SyncCollectionTile(
                  name: 'Listes départements (departmentManualLists)',
                  icon: Icons.list_alt_outlined,
                  synced: isConnected,
                ),
                _SyncCollectionTile(
                  name: 'Rôles (media_roles)',
                  icon: Icons.badge_outlined,
                  synced: isConnected,
                ),
                const SizedBox(height: 24),
                if (isOwner) ...[
                  AdvancedButton(
                    label: 'Synchroniser tout',
                    icon: Icons.cloud_sync,
                    variant: AdvancedButtonVariant.sync,
                    isLoading: _syncAllLoading,
                    onPressed: _syncAllLoading ? null : _syncAllSystem,
                  ),
                  const SizedBox(height: 12),
                ],
                AdvancedButton(
                  label: 'Forcer la synchronisation',
                  icon: Icons.sync,
                  variant: AdvancedButtonVariant.sync,
                  isLoading: syncStatus.isSyncing,
                  onPressed: syncStatus.isSyncing ? null : _forceSync,
                ),
                const SizedBox(height: 12),
                AdvancedButton(
                  label: 'Actions en attente',
                  icon: Icons.pending_actions,
                  variant: AdvancedButtonVariant.secondary,
                  onPressed: () => context.push('/admin/sync/pending'),
                ),
                const SizedBox(height: 12),
                AdvancedButton(
                  label: 'Centre de conflits',
                  icon: Icons.merge_type,
                  variant: AdvancedButtonVariant.secondary,
                  onPressed: () => context.push('/admin/sync/conflicts'),
                ),
                const SizedBox(height: 12),
                AdvancedButton(
                  label: 'Actualiser le statut',
                  icon: Icons.refresh,
                  variant: AdvancedButtonVariant.secondary,
                  onPressed: _refreshStatus,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class _SyncCollectionTile extends StatelessWidget {
  const _SyncCollectionTile({
    required this.name,
    required this.icon,
    required this.synced,
  });

  final String name;
  final IconData icon;
  final bool synced;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.goldAccent),
      title: Text(name, style: const TextStyle(fontSize: 14)),
      trailing: Icon(
        synced ? Icons.check_circle : Icons.schedule,
        color: synced ? AppTheme.success : AppTheme.goldAccent,
        size: 20,
      ),
    );
  }
}
