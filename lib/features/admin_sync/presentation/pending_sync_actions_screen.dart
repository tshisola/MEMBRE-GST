import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../core/bootstrap/background_sync_host.dart';
import '../../../core/providers/background_sync_providers.dart';
import '../../../core/widgets/app_shell_screens.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../shared/components/pop_scope_back_guard.dart';
import '../../../shared/components/app_drawer.dart';
import '../../../shared/components/member_sync_ui_kit.dart';
import '../../../shared/components/screen_header.dart';

/// Admin — actions en attente dans offline_sync_queue.
class PendingSyncActionsScreen extends ConsumerWidget {
  const PendingSyncActionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingSyncActionsProvider);
    final syncState = ref.watch(backgroundSyncStateProvider);

    return PopScopeBackGuard(
      fallbackRoute: '/admin/sync',
      child: Scaffold(
      backgroundColor: AppTheme.premiumBlack,
      drawer: const AppDrawer(currentRoute: '/admin/sync/pending'),
      appBar: AppBar(
        backgroundColor: AppTheme.cardDark,
        leading: const AppBackButton(fallbackRoute: '/admin/sync'),
        title: const Text('Actions en attente'),
        actions: [
          RefreshButton(
            compact: true,
            onRefresh: () async {
              await ref.read(autoSyncManagerProvider).runBackgroundSync(
                    trigger: 'manual_refresh',
                    forcePull: true,
                  );
              ref.invalidate(pendingSyncActionsProvider);
              return 'Données à jour';
            },
          ),
        ],
      ),
      body: pendingAsync.when(
        loading: () => const AppLoadingScreen(message: 'Chargement…'),
        error: (e, _) => AppErrorScreen(
          technicalError: e,
          onRetry: () => ref.invalidate(pendingSyncActionsProvider),
        ),
        data: (items) {
          return ListView(
            children: [
              ScreenHeader(
                title: '${items.length} action(s)',
                subtitle: 'Synchronisation en attente',
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: AdminSyncControlCard(
                  state: syncState,
                  onForceSync: () {
                    ref.read(autoSyncManagerProvider).runBackgroundSync(
                          trigger: 'force',
                          forcePull: true,
                        );
                    ref.invalidate(pendingSyncActionsProvider);
                  },
                ),
              ),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('Aucune action en attente.')),
                )
              else
                ...items.map(
                  (item) => PendingActionTile(
                    actionType: item.actionType,
                    entityId: item.entityId,
                    status: item.status,
                    error: item.lastError,
                  ),
                ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/admin/sync/conflicts'),
                  icon: const Icon(Icons.merge_type),
                  label: const Text('Voir les conflits'),
                ),
              ),
            ],
          );
        },
      ),
    ),
    );
  }
}
