import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/constants.dart';
import '../../app/theme.dart';
import '../ui/global_loading_controller.dart';
import '../firebase/firebase_initializer.dart';
import '../providers/app_providers.dart';
import '../providers/background_sync_providers.dart';
import '../sync/auto_sync_manager.dart';
import '../sync/sync_on_app_resume.dart';
import 'app_initializer.dart';
import '../production/smart_automation_engine.dart';
import '../smart/automation/smart_automation_center.dart';
import '../advanced/automation/advanced_automation_center.dart';
import '../../features/admin_realtime/presentation/members_live_provider.dart';
import '../../features/media_attendance/presentation/media_attendance_members_provider.dart';
import '../members/member_visibility_service.dart';
import '../messaging/user_friendly_error_mapper.dart';

export '../sync/sync_on_app_resume.dart';

/// Boots background sync, realtime listeners, and lifecycle observers.
class BackgroundSyncHost extends ConsumerStatefulWidget {
  const BackgroundSyncHost({
    super.key,
    required this.child,
    this.routePath = '/login',
  });

  final Widget child;
  final String routePath;

  @override
  ConsumerState<BackgroundSyncHost> createState() => _BackgroundSyncHostState();
}

class _BackgroundSyncHostState extends ConsumerState<BackgroundSyncHost> {
  SyncOnAppResumeService? _resumeService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Sync silencieuse — après affichage complet de l'UI (connexion).
      Future<void>.delayed(const Duration(seconds: 4), () {
        if (mounted) _bootstrap();
      });
    });
  }

  Future<void> _bootstrap() async {
    final autoSync = ref.read(autoSyncManagerProvider);
    final session = await ref.read(localSessionProvider.future);

    autoSync.onStateChanged = (state) {
      if (!mounted) return;
      ref.read(backgroundSyncStateProvider.notifier).state = state;
    };

    await autoSync.initialize(session: session);

    final memberAutoSync = ref.read(memberAutoSyncServiceProvider);
    memberAutoSync.onDataUpdated = () {
      if (!mounted) return;
      ref.read(membersRevisionProvider.notifier).state++;
      ref.read(mediaPointageMembersRevisionProvider.notifier).state++;
    };
    await memberAutoSync.startForSession(session);

    if (MemberVisibilityService.canReceiveMemberRealtime(session) &&
        FirebaseInitializer.isInitialized) {
      ref.read(membersRealtimeControllerProvider).start();
    }

    _resumeService = SyncOnAppResumeService(autoSync: autoSync)..start();

    unawaited(_runDeferredBackgroundTasks());
  }

  Future<void> _runDeferredBackgroundTasks() async {
    await AppInitializer.runDeferredSync();
    await SmartAutomationEngine.instance.runPostSyncAutomations();
    await SmartAutomationCenter.instance.onAfterSync();
    await AdvancedAutomationCenter.instance.onAfterSync();
    await AdvancedAutomationCenter.instance.onAppStart();
  }

  @override
  void dispose() {
    _resumeService?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Sync 100 % arrière-plan — aucun badge à l'ouverture ni sur login.
    // Les admins voient l'état dans Paramètres / Sync (écrans dédiés).
    if (isAuthPublicRoute(widget.routePath)) {
      return widget.child;
    }

    final syncState = ref.watch(backgroundSyncStateProvider);
    final sessionAsync = ref.watch(localSessionProvider);

    return Stack(
      children: [
        widget.child,
        sessionAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (session) {
            if (!session.isLoggedIn || !session.isAdminAccount) {
              return const SizedBox.shrink();
            }
            if (session.role != AppConstants.roleAdminGeneral) {
              return const SizedBox.shrink();
            }
            if (syncState.phase != BackgroundSyncPhase.error) {
              return const SizedBox.shrink();
            }
            return Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: BackgroundSyncIndicator(
                    state: syncState,
                    detailed: true,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Discrete admin sync indicator.
class BackgroundSyncIndicator extends StatelessWidget {
  const BackgroundSyncIndicator({
    super.key,
    required this.state,
    this.detailed = false,
  });

  final BackgroundSyncState state;
  final bool detailed;

  @override
  Widget build(BuildContext context) {
    final (color, icon, label) = _style(state.phase);
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(24),
      color: AppTheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (state.phase == BackgroundSyncPhase.syncing)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            else
              Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              detailed ? _adminLabel(state) : label,
              style: TextStyle(fontSize: 11, color: color),
            ),
          ],
        ),
      ),
    );
  }

  static (Color, IconData, String) _style(BackgroundSyncPhase phase) {
    switch (phase) {
      case BackgroundSyncPhase.syncing:
        return (const Color(0xFF42A5F5), Icons.sync, 'Synchronisation…');
      case BackgroundSyncPhase.pending:
        return (const Color(0xFFFFB74D), Icons.schedule, 'En attente');
      case BackgroundSyncPhase.offline:
        return (AppTheme.textSecondary, Icons.cloud_off, 'Hors ligne');
      case BackgroundSyncPhase.error:
        return (AppTheme.danger, Icons.error_outline, 'Erreur sync');
      case BackgroundSyncPhase.synced:
        return (AppTheme.success, Icons.cloud_done, 'Synchronisé');
      case BackgroundSyncPhase.idle:
        return (AppTheme.textSecondary, Icons.check, 'À jour');
    }
  }

  String _adminLabel(BackgroundSyncState state) {
    if (state.pendingCount > 0) {
      return '${state.pendingCount} action(s) en attente';
    }
    if (state.failedCount > 0) {
      return '${state.failedCount} erreur(s) sync';
    }
    return state.message ?? 'Données à jour';
  }
}

/// Minimal sync badge for members.
class MemberSimpleSyncBadge extends StatelessWidget {
  const MemberSimpleSyncBadge({super.key, required this.state});

  final BackgroundSyncState state;

  @override
  Widget build(BuildContext context) {
    if (state.phase == BackgroundSyncPhase.syncing) {
      return const SizedBox.shrink();
    }
    final isOk = state.phase == BackgroundSyncPhase.synced ||
        state.phase == BackgroundSyncPhase.idle;
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(20),
      color: AppTheme.surfaceElevated.withValues(alpha: 0.95),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isOk ? Icons.check_circle : Icons.cloud_queue,
              size: 14,
              color: isOk ? AppTheme.success : const Color(0xFFFFB74D),
            ),
            const SizedBox(width: 6),
            Text(
              state.memberMessage,
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppTheme.surfaceElevated,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: const Row(
        children: [
          Icon(Icons.wifi_off, size: 16, color: Color(0xFFFFB74D)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Mode hors ligne — vos données restent enregistrées localement.',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class OnlineBanner extends StatelessWidget {
  const OnlineBanner({super.key, this.message = 'Connexion rétablie — synchronisation…'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppTheme.success.withValues(alpha: 0.15),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.wifi, size: 16, color: AppTheme.success),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}

class PendingActionTile extends StatelessWidget {
  const PendingActionTile({
    super.key,
    required this.actionType,
    required this.entityId,
    required this.status,
    this.error,
  });

  final String actionType;
  final String entityId;
  final String status;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final displayError = error != null
        ? UserFriendlyErrorMapper.map(
            error,
            fallback: 'Synchronisation en attente.',
          )
        : entityId;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(
          status == AppConstants.queueStatusFailed
              ? Icons.error_outline
              : Icons.pending_actions,
          color: status == AppConstants.queueStatusFailed
              ? AppTheme.danger
              : const Color(0xFFFFB74D),
        ),
        title: Text(actionType, style: const TextStyle(fontSize: 13)),
        subtitle: Text(
          displayError,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11),
        ),
        trailing: Text(status, style: const TextStyle(fontSize: 10)),
      ),
    );
  }
}

class AdminSyncControlCard extends StatelessWidget {
  const AdminSyncControlCard({
    super.key,
    required this.state,
    required this.onForceSync,
    this.isLoading = false,
  });

  final BackgroundSyncState state;
  final VoidCallback onForceSync;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Synchronisation automatique',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'La sync s\'exécute en arrière-plan. Le bouton Actualiser force une lecture Firebase.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary.withValues(alpha: 0.9)),
            ),
            const SizedBox(height: 12),
            BackgroundSyncIndicator(state: state, detailed: true),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: isLoading ? null : onForceSync,
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh, color: Color(0xFF42A5F5)),
              label: const Text('Forcer actualisation'),
            ),
          ],
        ),
      ),
    );
  }
}

class MemberLivePercentageCard extends StatelessWidget {
  const MemberLivePercentageCard({
    super.key,
    required this.percentage,
    required this.isEligible,
  });

  final double percentage;
  final bool isEligible;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              '${percentage.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: isEligible ? AppTheme.success : AppTheme.danger,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isEligible ? 'Habilité' : 'Non habilité',
              style: TextStyle(
                color: isEligible ? AppTheme.success : AppTheme.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Mis à jour automatiquement',
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
