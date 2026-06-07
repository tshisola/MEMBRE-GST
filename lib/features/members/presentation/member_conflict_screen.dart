import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/constants.dart';
import '../../../app/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/sync/conflict_resolver.dart';
import '../../../features/admin_realtime/presentation/members_live_provider.dart';
import '../../../features/members/data/conflict_log_repository.dart';
import '../../../core/messaging/app_error_presenter.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../shared/components/app_drawer.dart';
import '../../../shared/components/pop_scope_back_guard.dart';
import '../../../shared/components/member_sync_ui_kit.dart';
import '../../../shared/components/premium_ui_kit.dart';
import '../../../shared/components/screen_header.dart';
import '../../../shared/models/sync_conflict_record.dart';

final conflictsListProvider = FutureProvider<List<SyncConflictRecord>>((ref) async {
  ref.watch(membersRevisionProvider);
  return ConflictLogRepository().listAll();
});

final unresolvedConflictsCountProvider = FutureProvider<int>((ref) async {
  ref.watch(membersRevisionProvider);
  return ConflictLogRepository().countUnresolved();
});

/// Centre de résolution des conflits sync local ↔ Firebase.
class MemberConflictScreen extends ConsumerStatefulWidget {
  const MemberConflictScreen({super.key});

  @override
  ConsumerState<MemberConflictScreen> createState() =>
      _MemberConflictScreenState();
}

class _MemberConflictScreenState extends ConsumerState<MemberConflictScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  bool _showResolved = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) {
        setState(() => _showResolved = _tabs.index == 1);
      }
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _resolve({
    required SyncConflictRecord conflict,
    required bool keepLocal,
  }) async {
    final resolver = ConflictResolver();
    if (keepLocal) {
      if (conflict.local == null) return;
      await resolver.resolveKeepLocal(
        conflictId: conflict.id,
        local: conflict.local!,
      );
    } else {
      if (conflict.remote == null) return;
      await resolver.resolveKeepRemote(
        conflictId: conflict.id,
        remote: conflict.remote!,
      );
    }
    bumpMembersRevision(ref);
    ref.invalidate(conflictsListProvider);
    ref.invalidate(unresolvedConflictsCountProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            keepLocal
                ? 'Version locale appliquée — ${conflict.memberCode}'
                : 'Version Firebase appliquée — ${conflict.memberCode}',
          ),
        ),
      );
    }
  }

  Future<void> _confirmResolve(
    SyncConflictRecord conflict, {
    required bool keepLocal,
  }) async {
    final role = await ref.read(userRoleProvider.future);
    if (role != AppConstants.roleAdminGeneral) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Seul l\'Admin Général peut résoudre manuellement un conflit.',
            ),
          ),
        );
      }
      return;
    }

    final side = keepLocal ? 'locale (SQLite)' : 'Firebase';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainer,
        title: const Text('Confirmer la résolution'),
        content: Text(
          'Appliquer la version $side pour ${conflict.memberLabel} ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _resolve(conflict: conflict, keepLocal: keepLocal);
    }
  }

  @override
  Widget build(BuildContext context) {
    final conflictsAsync = ref.watch(conflictsListProvider);
    final roleAsync = ref.watch(userRoleProvider);
    final isAdminGeneral = roleAsync.value == AppConstants.roleAdminGeneral;

    return PopScopeBackGuard(
      fallbackRoute: '/admin/sync',
      child: Scaffold(
      backgroundColor: AppTheme.premiumBlack,
      drawer: const AppDrawer(currentRoute: '/admin/sync/conflicts'),
      appBar: AppBar(
        backgroundColor: AppTheme.cardDark,
        leading: const AppBackButton(fallbackRoute: '/admin/sync'),
        title: const Text('Centre de conflits'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'En attente'),
            Tab(text: 'Résolus'),
          ],
        ),
        actions: [
          RefreshButton(
            compact: true,
            onRefresh: () async {
              ref.invalidate(conflictsListProvider);
              bumpMembersRevision(ref);
              return 'Données à jour';
            },
          ),
        ],
      ),
      body: conflictsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            AppErrorPresenter.forUser(e, source: 'conflicts'),
            textAlign: TextAlign.center,
          ),
        ),
        data: (all) {
          final items = all.where((c) => c.resolved == _showResolved).toList();
          if (items.isEmpty) {
            return ListView(
              children: [
                ScreenHeader(
                  title: _showResolved ? 'Conflits résolus' : 'Aucun conflit',
                  subtitle: _showResolved
                      ? 'Historique des résolutions manuelles'
                      : 'Local et Firebase sont alignés',
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            _showResolved ? Icons.history : Icons.check_circle,
                            size: 56,
                            color: _showResolved
                                ? AppTheme.textSecondary
                                : AppTheme.success,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _showResolved
                                ? 'Aucun conflit résolu enregistré.'
                                : 'Aucun conflit en attente.',
                            textAlign: TextAlign.center,
                          ),
                          if (!_showResolved) ...[
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: () => context.go('/admin/sync'),
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Retour sync'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: items.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return ScreenHeader(
                  title: _showResolved
                      ? '${items.length} conflit(s) résolu(s)'
                      : '${items.length} conflit(s) en attente',
                  subtitle: 'Comparaison SQLite ↔ Firestore',
                );
              }
              final conflict = items[index - 1];
              return _ConflictCard(
                conflict: conflict,
                isAdminGeneral: isAdminGeneral,
                showActions: !_showResolved,
                onKeepLocal: () =>
                    _confirmResolve(conflict, keepLocal: true),
                onKeepRemote: () =>
                    _confirmResolve(conflict, keepLocal: false),
                onOpenMember: () => context.push('/members/${conflict.memberId}'),
              );
            },
          );
        },
      ),
    ),
    );
  }
}

class _ConflictCard extends StatelessWidget {
  const _ConflictCard({
    required this.conflict,
    required this.isAdminGeneral,
    required this.showActions,
    required this.onKeepLocal,
    required this.onKeepRemote,
    required this.onOpenMember,
  });

  final SyncConflictRecord conflict;
  final bool isAdminGeneral;
  final bool showActions;
  final VoidCallback onKeepLocal;
  final VoidCallback onKeepRemote;
  final VoidCallback onOpenMember;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
    final local = conflict.local;
    final remote = conflict.remote;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.merge_type, color: Color(0xFFCE93D8)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    conflict.memberLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (conflict.resolved)
                  const SyncStatusBadge(
                    status: AppConstants.syncStatusSynced,
                    compact: false,
                  )
                else
                  const SyncStatusBadge(
                    status: AppConstants.syncStatusConflict,
                    compact: false,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              conflict.memberCode,
              style: const TextStyle(
                color: AppTheme.goldAccent,
                fontSize: 12,
              ),
            ),
            Text(
              'Détecté le ${dateFmt.format(conflict.createdAt)}',
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _VersionPanel(
                    title: 'Local (SQLite)',
                    color: const Color(0xFF42A5F5),
                    name: local?.displayName,
                    phone: local?.phone,
                    updated: local?.updatedAt,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _VersionPanel(
                    title: 'Firebase',
                    color: AppTheme.success,
                    name: remote?.displayName,
                    phone: remote?.phone,
                    updated: remote?.updatedAt,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton.icon(
                  onPressed: onOpenMember,
                  icon: const Icon(Icons.person, size: 18),
                  label: const Text('Voir membre'),
                ),
              ],
            ),
            if (showActions) ...[
              const Divider(),
              if (!isAdminGeneral)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Résolution manuelle réservée à l\'Admin Général.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isAdminGeneral ? onKeepLocal : null,
                      icon: const Icon(Icons.phone_android, size: 18),
                      label: const Text('Garder local'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF42A5F5),
                        side: const BorderSide(color: Color(0xFF42A5F5)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: isAdminGeneral ? onKeepRemote : null,
                      icon: const Icon(Icons.cloud, size: 18),
                      label: const Text('Garder Firebase'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.goldAccent,
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _VersionPanel extends StatelessWidget {
  const _VersionPanel({
    required this.title,
    required this.color,
    this.name,
    this.phone,
    this.updated,
  });

  final String title;
  final Color color;
  final String? name;
  final String? phone;
  final DateTime? updated;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yy HH:mm');
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(name ?? '—', style: const TextStyle(fontSize: 12)),
          if (phone != null && phone!.isNotEmpty)
            Text('Tél: $phone', style: const TextStyle(fontSize: 11)),
          if (updated != null)
            Text(
              'MAJ: ${fmt.format(updated!)}',
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}
