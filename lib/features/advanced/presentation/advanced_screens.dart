import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/advanced/actions/auto_fix_action_service.dart';
import '../../../core/advanced/approval/approval_workflow_service.dart';
import '../../../core/advanced/audit/professional_audit_log_service.dart';
import '../../../core/advanced/models/advanced_models.dart';
import '../../../core/advanced/notifications/local_notification_repository.dart';
import '../../../core/advanced/notifications/push_notification_service.dart';
import '../../../core/advanced/notifications/notification_preferences_service.dart';
import '../../../core/advanced/pdf/smart_pdf_report_service.dart';
import '../../../core/navigation/app_deep_link_service.dart';
import '../../../core/advanced/pdf/pdf_preview_cache.dart';
import '../../../core/messaging/user_friendly_message_service.dart';
import 'pdf_preview_screen.dart';
import '../../../core/smart/models/smart_models.dart';
import '../../../core/advanced/live/live_media_activity_engine.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../shared/components/advanced_design_system.dart';
import '../../../shared/components/app_drawer.dart';
import '../../../shared/components/pop_scope_back_guard.dart';
import '../../../shared/components/premium_admin_scaffold.dart';
import '../../../shared/components/smart_ui_kit.dart';
import 'advanced_providers.dart';

/// Centre de notifications professionnel.
class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  ConsumerState<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends ConsumerState<NotificationCenterScreen> {
  String _filter = 'Toutes';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(notificationsProvider);
    return PopScopeBackGuard(
      fallbackRoute: '/dashboard',
      child: Scaffold(
        backgroundColor: AppTheme.premiumBlack,
        drawer: const AppDrawer(currentRoute: '/advanced/notifications'),
        appBar: AppBar(
          leading: null,
          title: const Text('Centre de notifications'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Paramètres',
              onPressed: () => context.push('/advanced/notifications/settings'),
            ),
            TextButton(
              onPressed: () async {
                await LocalNotificationRepository.instance.markAllRead();
                ref.invalidate(notificationsProvider);
                ref.invalidate(unreadNotificationsCountProvider);
              },
              child: const Text('Tout lu'),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilterChipGroup(
                labels: const ['Toutes', 'Critiques', 'Présence', 'Listes', 'Comptes'],
                selected: _filter,
                onSelected: (v) => setState(() => _filter = v),
              ),
            ),
            Expanded(
              child: async.when(
                loading: () => ListView.builder(
                  itemCount: 4,
                  itemBuilder: (_, __) => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: LoadingSkeleton(),
                  ),
                ),
                error: (_, __) => EmptyStatePremium(
                  title: 'Notifications indisponibles',
                  subtitle: UserFriendlyMessageService.genericError(),
                ),
                data: (items) {
                  final filtered = _applyFilter(items);
                  if (filtered.isEmpty) {
                    return const EmptyStatePremium(
                      title: 'Aucune notification',
                      subtitle: 'Vous êtes à jour.',
                      icon: Icons.notifications_none_outlined,
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final n = filtered[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: NotificationCard(
                          title: n.title,
                          message: n.message,
                          isRead: n.isRead,
                          severityColor: _severityColor(n.severity),
                          onOpen: n.route != null
                              ? () async {
                                  final session =
                                      await ref.read(localSessionProvider.future);
                                  if (!context.mounted) return;
                                  await AppDeepLinkService.instance.open(
                                    GoRouter.of(context),
                                    route: n.route!,
                                    session: session,
                                  );
                                }
                              : null,
                          onDismiss: n.isRead
                              ? null
                              : () async {
                                  await LocalNotificationRepository.instance
                                      .markRead(n.id);
                                  ref.invalidate(notificationsProvider);
                                  ref.invalidate(unreadNotificationsCountProvider);
                                },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<AppNotificationItem> _applyFilter(List<AppNotificationItem> items) {
    switch (_filter) {
      case 'Critiques':
        return items.where((n) => n.severity == AppNotificationSeverity.critical).toList();
      case 'Présence':
        return items.where((n) => n.category == AppNotificationCategory.attendance).toList();
      case 'Listes':
        return items.where((n) => n.category == AppNotificationCategory.list).toList();
      case 'Comptes':
        return items.where((n) => n.category == AppNotificationCategory.account).toList();
      default:
        return items;
    }
  }

  Color _severityColor(AppNotificationSeverity s) {
    switch (s) {
      case AppNotificationSeverity.critical:
        return AppTheme.errorProd;
      case AppNotificationSeverity.warning:
        return AppTheme.warningProd;
      case AppNotificationSeverity.info:
        return AppTheme.brandBlue;
    }
  }
}

/// Paramètres notifications.
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  bool _critical = true;
  bool _lists = true;
  bool _accounts = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final service = NotificationPreferencesService(prefs);
    if (!mounted) return;
    setState(() {
      _critical = service.criticalAlerts;
      _lists = service.listsAndAttendance;
      _accounts = service.accountsAndActivation;
      _loading = false;
    });
  }

  Future<void> _save(Future<void> Function(NotificationPreferencesService) fn) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await fn(NotificationPreferencesService(prefs));
  }

  @override
  Widget build(BuildContext context) {
    return PopScopeBackGuard(
      fallbackRoute: '/advanced/notifications',
      child: Scaffold(
        backgroundColor: AppTheme.premiumBlack,
        appBar: AppBar(
          leading: const AppBackButton(fallbackRoute: '/advanced/notifications'),
          title: const Text('Paramètres notifications'),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const GradientHeader(
                    title: 'Alertes MEDIA LUBUMBASHI',
                    subtitle: 'Notifications push et locales',
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Alertes critiques'),
                    subtitle: const Text('Membres invisibles, sync, QR manquants'),
                    value: _critical,
                    onChanged: (v) async {
                      setState(() => _critical = v);
                      await _save((s) => s.setCriticalAlerts(v));
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Listes et pointage'),
                    subtitle: const Text('Listes dimanche, présence'),
                    value: _lists,
                    onChanged: (v) async {
                      setState(() => _lists = v);
                      await _save((s) => s.setListsAndAttendance(v));
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Comptes et activation'),
                    subtitle: const Text('Nouveaux membres, activations Google'),
                    value: _accounts,
                    onChanged: (v) async {
                      setState(() => _accounts = v);
                      await _save((s) => s.setAccountsAndActivation(v));
                    },
                  ),
                ],
              ),
      ),
    );
  }
}

/// Centre de commande intelligent Admin.
class CommandCenterScreen extends ConsumerWidget {
  const CommandCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(commandCenterProvider);
    return PopScopeBackGuard(
      fallbackRoute: '/dashboard',
      child: PremiumAdminScaffold(
        currentRoute: '/advanced/command-center',
        title: 'Centre Intelligent Admin',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(commandCenterProvider),
          ),
        ],
        body: snap.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(child: Text(UserFriendlyMessageService.genericError())),
          data: (s) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GradientHeader(
                title: 'Score Santé MEDIA LUBUMBASHI',
                subtitle: 'État global de l\'application',
              ),
              const SizedBox(height: 12),
              SmartScoreCard(
                label: 'Score santé',
                score: s.healthScore,
                icon: Icons.health_and_safety_outlined,
                color: _healthColor(s.healthScore),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _miniStat('Actifs', '${s.activeMembers}', AppTheme.goldAccent),
                  _miniStat('Supprimés', '${s.deletedMembers}', AppTheme.textMuted),
                  _miniStat('Pointage OK', '${s.visibleAtPointage}', AppTheme.successProd),
                  _miniStat('Invisibles', '${s.invisibleAtPointage}', AppTheme.errorProd),
                  _miniStat('Listes', '${s.totalListsGenerated}', AppTheme.brandBlue),
                  _miniStat('Incomplètes', '${s.incompleteLists}', AppTheme.warningProd),
                  _miniStat('Présents', '${s.todayPresent}', AppTheme.successProd),
                  _miniStat('Retards', '${s.todayLate}', AppTheme.warningProd),
                  _miniStat('Absents', '${s.todayAbsent}', AppTheme.errorProd),
                  _miniStat('QR manquants', '${s.qrMissingCount}', AppTheme.warningProd),
                  _miniStat('Sync attente', '${s.pendingSync}', AppTheme.brandBlue),
                ],
              ),
              const SizedBox(height: 16),
              SmartScoreCard(label: 'Synchronisation', score: s.syncScore, icon: Icons.cloud_sync),
              SmartScoreCard(label: 'Qualité données', score: s.dataQualityScore, icon: Icons.fact_check),
              SmartScoreCard(label: 'Pointage', score: s.pointageScore, icon: Icons.groups),
              const SizedBox(height: 16),
              const Text('Actions recommandées', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...s.recommendations.asMap().entries.map(
                (e) => SmartRecommendationCard(
                  recommendation: SmartRecommendation(
                    id: 'rec_${e.key}',
                    title: e.value,
                    description: '',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SmartActionButton(
                label: 'Actions rapides',
                icon: Icons.bolt,
                onPressed: () => context.push('/advanced/quick-actions'),
              ),
              const SizedBox(height: 8),
              SmartActionButton(
                label: 'Rapport live activité',
                icon: Icons.live_tv,
                onPressed: () => context.push('/advanced/live'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return PremiumCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      borderColor: color.withValues(alpha: 0.3),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 18)),
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
        ],
      ),
    );
  }

  Color _healthColor(int score) {
    if (score >= 80) return AppTheme.successProd;
    if (score >= 60) return AppTheme.warningProd;
    return AppTheme.errorProd;
  }
}

/// Panel actions rapides.
class SmartQuickActionsScreen extends ConsumerStatefulWidget {
  const SmartQuickActionsScreen({super.key});

  @override
  ConsumerState<SmartQuickActionsScreen> createState() => _SmartQuickActionsScreenState();
}

class _SmartQuickActionsScreenState extends ConsumerState<SmartQuickActionsScreen> {
  bool _loading = false;

  Future<void> _run(String key, {bool confirm = false}) async {
    if (confirm) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Confirmer'),
          content: const Text('Voulez-vous exécuter cette action ?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmer')),
          ],
        ),
      );
      if (ok != true) return;
    }
    setState(() => _loading = true);
    final session = await ref.read(localSessionProvider.future);
    final service = ref.read(autoFixActionServiceProvider);
    SmartActionHistoryEntry? result;
    try {
      switch (key) {
        case 'fix_invisible_pointage':
          result = await service.fixInvisiblePointage(
            actorId: session.userId,
            actorName: session.displayName,
          );
        case 'generate_sunday_lists':
          result = await service.generateSundayLists(
            actorId: session.userId,
            actorName: session.displayName,
          );
        case 'verify_qr_codes':
          result = await service.verifyQrCodes(
            actorId: session.userId,
            actorName: session.displayName,
          );
        case 'retry_auto_update':
          result = await service.retryAutoUpdate(
            actorId: session.userId,
            actorName: session.displayName,
          );
        case 'merge_duplicates':
          result = await ref.read(quickActionServiceProvider).run(
                'merge_duplicates',
                actorId: session.userId,
                actorName: session.displayName,
              );
          if (mounted) context.push('/advanced/duplicate-merge');
        case 'preview_last_pdf':
          result = await ref.read(quickActionServiceProvider).run(
                'preview_last_pdf',
                actorId: session.userId,
                actorName: session.displayName,
              );
          if (mounted && PdfPreviewCache.instance.get('last_pdf') != null) {
            context.push('/advanced/pdf-preview?key=last_pdf');
          }
        case 'verify_media_requests':
          result = await ref.read(quickActionServiceProvider).run(
                'verify_media_requests',
                actorId: session.userId,
                actorName: session.displayName,
              );
          if (mounted) context.push('/admin/media-activation-requests');
        case 'open_diagnostic':
          result = await ref.read(quickActionServiceProvider).run(
                'open_diagnostic',
                actorId: session.userId,
                actorName: session.displayName,
              );
          if (mounted) context.push('/admin/diagnostic');
        case 'fix_incomplete_lists':
          result = await service.fixIncompleteLists(
            actorId: session.userId,
            actorName: session.displayName,
          );
        case 'retry_sync':
          result = await service.retrySync(
            actorId: session.userId,
            actorName: session.displayName,
          );
        case 'fix_missing_data':
          result = await service.fixMissingData(
            actorId: session.userId,
            actorName: session.displayName,
          );
        case 'prepare_exports':
          result = await service.prepareExports(
            actorId: session.userId,
            actorName: session.displayName,
            responsible: session.displayName,
          );
        case 'verify_attendance':
          result = await service.verifyAttendance(
            actorId: session.userId,
            actorName: session.displayName,
          );
        case 'verify_inactive_accounts':
          result = await service.verifyInactiveAccounts(
            actorId: session.userId,
            actorName: session.displayName,
          );
        case 'verify_deleted_members':
          result = await service.verifyDeletedMembers(
            actorId: session.userId,
            actorName: session.displayName,
          );
        case 'export_report':
          result = await service.exportIntelligentReport(
            actorId: session.userId,
            actorName: session.displayName,
            responsible: session.displayName,
          );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result?.success == true
                ? (result?.message ?? UserFriendlyMessageService.success())
                : UserFriendlyMessageService.genericError(),
          ),
        ),
      );
      ref.invalidate(commandCenterProvider);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScopeBackGuard(
      fallbackRoute: '/advanced/command-center',
      child: Scaffold(
        backgroundColor: AppTheme.premiumBlack,
        drawer: const AppDrawer(currentRoute: '/advanced/quick-actions'),
        appBar: AppBar(
          leading: null,
          title: const Text('Actions rapides'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final a in SmartQuickActionsPanel.actions)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SmartActionButton(
                  label: a.$2,
                  loading: _loading,
                  danger: a.$3,
                  onPressed: _loading ? null : () => _run(a.$1, confirm: a.$3),
                ),
              ),
            SmartActionButton(
              label: 'Voir l\'historique',
              icon: Icons.history,
              onPressed: _loading ? null : () => context.push('/advanced/action-history'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Demandes de validation.
class ApprovalRequestsScreen extends ConsumerWidget {
  const ApprovalRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(approvalRequestsProvider);
    return PopScopeBackGuard(
      fallbackRoute: '/dashboard',
      child: Scaffold(
        backgroundColor: AppTheme.premiumBlack,
        appBar: AppBar(
          leading: const AppBackButton(fallbackRoute: '/dashboard'),
          title: const Text('Validations'),
        ),
        body: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(child: Text(UserFriendlyMessageService.genericError())),
          data: (items) {
            if (items.isEmpty) {
              return const EmptyStatePremium(title: 'Aucune demande', subtitle: 'Tout est validé.');
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final item = items[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ApprovalCard(
                    title: item.actionLabel,
                    subtitle: '${item.targetLabel}\n${item.reason ?? ''}',
                    status: item.status == ApprovalStatus.pending
                        ? ApprovalStatusBadge.pending()
                        : item.status == ApprovalStatus.approved
                            ? ApprovalStatusBadge.approved()
                            : ApprovalStatusBadge.rejected(),
                    onApprove: item.status == ApprovalStatus.pending
                        ? () async {
                            await ApprovalWorkflowService.instance.approve(
                              id: item.id,
                              decidedBy: 'admin',
                            );
                            ref.invalidate(approvalRequestsProvider);
                          }
                        : null,
                    onReject: item.status == ApprovalStatus.pending
                        ? () async {
                            await ApprovalWorkflowService.instance.reject(
                              id: item.id,
                              decidedBy: 'admin',
                              decisionReason: 'Refusé par administrateur',
                            );
                            ref.invalidate(approvalRequestsProvider);
                          }
                        : null,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Audit professionnel avec filtres.
class AuditTimelineScreen extends ConsumerStatefulWidget {
  const AuditTimelineScreen({super.key});

  @override
  ConsumerState<AuditTimelineScreen> createState() => _AuditTimelineScreenState();
}

class _AuditTimelineScreenState extends ConsumerState<AuditTimelineScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(auditTimelineProvider);
    return PopScopeBackGuard(
      fallbackRoute: '/dashboard',
      child: Scaffold(
        backgroundColor: AppTheme.premiumBlack,
        appBar: AppBar(
          leading: const AppBackButton(fallbackRoute: '/dashboard'),
          title: const Text('Audit professionnel'),
          actions: [
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              onPressed: () async {
                final data = async.valueOrNull ?? [];
                await AuditExportPdfService().share(data);
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: AdvancedSearchBar(controller: _search, hint: 'Filtrer par action…'),
            ),
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(child: Text(UserFriendlyMessageService.genericError())),
                data: (entries) {
                  final q = _search.text.trim().toLowerCase();
                  final filtered = q.isEmpty
                      ? entries
                      : entries.where((e) => e.action.toLowerCase().contains(q)).toList();
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final e = filtered[i];
                      return PremiumCard(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.action, style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text(
                              '${e.module ?? '—'} · ${e.createdAt.toString().substring(0, 16)}',
                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DuplicateWarningScreen extends ConsumerWidget {
  const DuplicateWarningScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(duplicatesProvider);
    return PopScopeBackGuard(
      fallbackRoute: '/advanced/command-center',
      child: Scaffold(
        backgroundColor: AppTheme.premiumBlack,
        drawer: const AppDrawer(currentRoute: '/advanced/duplicates'),
        appBar: AppBar(
          leading: null,
          title: const Text('Doublons détectés'),
        ),
        body: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(child: Text(UserFriendlyMessageService.genericError())),
          data: (matches) {
            if (matches.isEmpty) {
              return const EmptyStatePremium(title: 'Aucun doublon', subtitle: 'Données propres.');
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: matches.length,
              itemBuilder: (_, i) {
                final m = matches[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SmartAlertCard(
                    issue: SmartIssue(
                      id: m.id,
                      title: m.memberName,
                      message: '${m.matchType} : ${m.matchValue}',
                      category: SmartIssueCategory.duplicate,
                      severity: SmartIssueSeverity.warning,
                    ),
                    onDetails: () => context.push('/members/${m.memberId}'),
                    onIgnore: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Alerte ignorée.')),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class PerformanceScreen extends ConsumerWidget {
  const PerformanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(performanceProvider);
    return PopScopeBackGuard(
      fallbackRoute: '/advanced/command-center',
      child: Scaffold(
        backgroundColor: AppTheme.premiumBlack,
        drawer: const AppDrawer(currentRoute: '/advanced/performance'),
        appBar: AppBar(
          leading: null,
          title: const Text('Performance application'),
        ),
        body: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(child: Text(UserFriendlyMessageService.genericError())),
          data: (p) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SmartScoreCard(label: 'Score performance', score: p.score, icon: Icons.speed),
              PremiumCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Niveau : ${p.level.label}'),
                    Text('Démarrage : ${p.startupMs} ms'),
                    Text('Requête moyenne : ${p.avgQueryMs} ms'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ...p.recommendations.asMap().entries.map(
                (e) => SmartRecommendationCard(
                  recommendation: SmartRecommendation(
                    id: 'perf_${e.key}',
                    title: e.value,
                    description: '',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MediaCalendarScreen extends ConsumerStatefulWidget {
  const MediaCalendarScreen({super.key});

  @override
  ConsumerState<MediaCalendarScreen> createState() => _MediaCalendarScreenState();
}

class _MediaCalendarScreenState extends ConsumerState<MediaCalendarScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(calendarEventsProvider(_month));
    return PopScopeBackGuard(
      fallbackRoute: '/dashboard',
      child: Scaffold(
        backgroundColor: AppTheme.premiumBlack,
        appBar: AppBar(
          leading: const AppBackButton(fallbackRoute: '/dashboard'),
          title: const Text('Calendrier Média'),
          actions: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => setState(() {
                _month = DateTime(_month.year, _month.month - 1);
              }),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => setState(() {
                _month = DateTime(_month.year, _month.month + 1);
              }),
            ),
          ],
        ),
        body: events.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(child: Text(UserFriendlyMessageService.genericError())),
          data: (list) => ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final e = list[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: PremiumCard(
                  borderColor: _eventColor(e.type),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text(
                              '${e.date.day}/${e.date.month}/${e.date.year}',
                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      StatusBadge(
                        label: e.isReady ? 'Prête' : 'Incomplète',
                        color: e.isReady ? AppTheme.successProd : AppTheme.warningProd,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Color _eventColor(CalendarEventType t) {
    switch (t) {
      case CalendarEventType.service:
        return AppTheme.brandOrange;
      case CalendarEventType.list:
        return AppTheme.brandBlue;
      case CalendarEventType.team:
        return AppTheme.successProd;
      case CalendarEventType.reminder:
        return AppTheme.goldAccent;
    }
  }
}

class LiveActivityScreen extends ConsumerStatefulWidget {
  const LiveActivityScreen({super.key});

  @override
  ConsumerState<LiveActivityScreen> createState() => _LiveActivityScreenState();
}

class _LiveActivityScreenState extends ConsumerState<LiveActivityScreen> {
  @override
  void initState() {
    super.initState();
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    Future<void>.delayed(const Duration(seconds: 30), () {
      if (!mounted) return;
      ref.invalidate(liveActivityProvider);
      ref.invalidate(replacementSuggestionsProvider);
      _startAutoRefresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final live = ref.watch(liveActivityProvider);
    final replacements = ref.watch(replacementSuggestionsProvider);
    return PopScopeBackGuard(
      fallbackRoute: '/advanced/command-center',
      child: Scaffold(
        backgroundColor: AppTheme.premiumBlack,
        drawer: const AppDrawer(currentRoute: '/advanced/live'),
        appBar: AppBar(
          leading: null,
          title: const Text('Activité en direct'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                ref.invalidate(liveActivityProvider);
                ref.invalidate(replacementSuggestionsProvider);
              },
            ),
          ],
        ),
        body: live.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(child: Text(UserFriendlyMessageService.genericError())),
          data: (s) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GradientHeader(
                title: LiveAttendanceCounter.label(s),
                subtitle: LiveRoleCoverageCard.coverageLabel(s),
              ),
              const SizedBox(height: 16),
              SmartProgressCard(label: 'Préparation service', percent: s.prepPercent),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _liveStat('Arrivés', s.arrivedCount, AppTheme.successProd),
                  _liveStat('Retards', s.lateCount, AppTheme.warningProd),
                  _liveStat('Absents', s.absentCount, AppTheme.errorProd),
                ],
              ),
              const SizedBox(height: 16),
              if (LiveAlertPanel.hasAlerts(s))
                ...s.alerts.map(
                  (a) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SmartAlertCard(
                      issue: SmartIssue(
                        id: 'live_$a',
                        title: 'Alerte',
                        message: a,
                        category: SmartIssueCategory.attendance,
                        severity: SmartIssueSeverity.warning,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              const Text('Remplacements proposés',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              replacements.when(
                loading: () => const LoadingSkeleton(),
                error: (_, __) => const SizedBox.shrink(),
                data: (items) {
                  if (items.isEmpty) {
                    return const EmptyStatePremium(
                      title: 'Aucun remplacement',
                      subtitle: 'Équipe stable pour le moment.',
                      icon: Icons.check_circle_outline,
                    );
                  }
                  return Column(
                    children: items
                        .map(
                          (r) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: ReplacementSuggestionCard(
                              post: r.postLabel,
                              absent: r.absentMemberName,
                              replacement: r.suggestedMemberName,
                              confidence: r.confidence,
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _liveStat(String label, int value, Color color) {
    return PremiumCard(
      padding: const EdgeInsets.all(12),
      borderColor: color.withValues(alpha: 0.3),
      child: Column(
        children: [
          Text('$value', style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w700)),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}

/// Hub rapports PDF intelligents.
class AdvancedReportHubScreen extends ConsumerStatefulWidget {
  const AdvancedReportHubScreen({super.key});

  @override
  ConsumerState<AdvancedReportHubScreen> createState() =>
      _AdvancedReportHubScreenState();
}

class _AdvancedReportHubScreenState extends ConsumerState<AdvancedReportHubScreen> {
  bool _exporting = false;

  Future<void> _export(SmartReportType type, String label) async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final pdf = ref.read(advancedPdfExportServiceProvider);
      final session = await ref.read(localSessionProvider.future);
      final bytes = await pdf.buildSmartReportBytes(
        type,
        responsible: session.displayName,
      );
      if (!mounted) return;
      await openPdfPreview(context, bytes: bytes, title: label);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(UserFriendlyMessageService.genericError())),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScopeBackGuard(
      fallbackRoute: '/advanced/command-center',
      child: Scaffold(
        backgroundColor: AppTheme.premiumBlack,
        drawer: const AppDrawer(currentRoute: '/advanced/report'),
        appBar: AppBar(
          leading: null,
          title: const Text('Rapports PDF intelligents'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_exporting)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator(),
              ),
            ReportCard(
              title: 'Présence du jour',
              subtitle: 'Export PDF professionnel',
              onTap: _exporting
                  ? null
                  : () => _export(SmartReportType.dailyAttendance, 'Présence du jour'),
            ),
            ReportCard(
              title: 'Présence semaine',
              subtitle: 'Synthèse hebdomadaire',
              onTap: _exporting
                  ? null
                  : () => _export(SmartReportType.weeklyAttendance, 'Présence semaine'),
            ),
            ReportCard(
              title: 'Média dimanche',
              subtitle: 'Liste et équipe du dimanche',
              onTap: _exporting
                  ? null
                  : () => _export(SmartReportType.sundayMedia, 'Rapport Média dimanche'),
            ),
            ReportCard(
              title: 'Membres retardataires',
              subtitle: 'Retards enregistrés',
              onTap: _exporting
                  ? null
                  : () => _export(SmartReportType.lateMembers, 'Rapport retardataires'),
            ),
            ReportCard(
              title: 'Membres absents',
              subtitle: 'Absences enregistrées',
              onTap: _exporting
                  ? null
                  : () => _export(SmartReportType.absentMembers, 'Rapport absents'),
            ),
            ReportCard(
              title: 'Qualité des données',
              subtitle: 'Score et problèmes',
              onTap: _exporting
                  ? null
                  : () => _export(SmartReportType.dataQuality, 'Qualité des données'),
            ),
            ReportCard(
              title: 'Synchronisation',
              subtitle: 'État sync Firebase / local',
              onTap: _exporting
                  ? null
                  : () => _export(SmartReportType.syncHealth, 'Synchronisation'),
            ),
            ReportCard(
              title: 'Intelligence Média',
              subtitle: 'Analyse globale',
              onTap: _exporting
                  ? null
                  : () => _export(SmartReportType.mediaIntelligence, 'Intelligence Média'),
            ),
            ReportCard(
              title: 'Performance membres',
              subtitle: 'Liste active',
              onTap: _exporting
                  ? null
                  : () => _export(SmartReportType.memberPerformance, 'Performance membres'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Remplacements automatiques proposés pour le dimanche.
class ReplacementSuggestionsScreen extends ConsumerWidget {
  const ReplacementSuggestionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(replacementSuggestionsProvider);
    return PopScopeBackGuard(
      fallbackRoute: '/advanced/command-center',
      child: Scaffold(
        backgroundColor: AppTheme.premiumBlack,
        drawer: const AppDrawer(currentRoute: '/advanced/replacements'),
        appBar: AppBar(
          leading: null,
          title: const Text('Remplacements proposés'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.invalidate(replacementSuggestionsProvider),
            ),
          ],
        ),
        body: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(child: Text(UserFriendlyMessageService.genericError())),
          data: (items) {
            if (items.isEmpty) {
              return const EmptyStatePremium(
                title: 'Aucun remplacement nécessaire',
                subtitle: 'L\'équipe du dimanche est stable.',
                icon: Icons.verified_outlined,
              );
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const GradientHeader(
                  title: 'Remplacement automatique',
                  subtitle: 'Membres à risque — suggestions intelligentes',
                ),
                const SizedBox(height: 12),
                ...items.map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ReplacementSuggestionCard(
                      post: r.postLabel,
                      absent: r.absentMemberName,
                      replacement: r.suggestedMemberName,
                      confidence: r.confidence,
                    ),
                  ),
                ),
                SmartActionButton(
                  label: 'Planification Média',
                  icon: Icons.groups,
                  onPressed: () => context.push('/smart/team-planning'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Historique des actions rapides intelligentes.
class SmartActionHistoryScreen extends ConsumerWidget {
  const SmartActionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(smartActionHistoryProvider);
    return PopScopeBackGuard(
      fallbackRoute: '/advanced/quick-actions',
      child: Scaffold(
        backgroundColor: AppTheme.premiumBlack,
        drawer: const AppDrawer(currentRoute: '/advanced/action-history'),
        appBar: AppBar(
          leading: null,
          title: const Text('Historique des actions'),
        ),
        body: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(child: Text(UserFriendlyMessageService.genericError())),
          data: (entries) {
            if (entries.isEmpty) {
              return const EmptyStatePremium(
                title: 'Aucune action enregistrée',
                subtitle: 'Les actions rapides apparaîtront ici.',
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              itemBuilder: (_, i) {
                final e = entries[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: PremiumCard(
                    borderColor: e.success
                        ? AppTheme.successProd.withValues(alpha: 0.3)
                        : AppTheme.warningProd.withValues(alpha: 0.3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                        if (e.message != null) ...[
                          const SizedBox(height: 4),
                          Text(e.message!, style: const TextStyle(fontSize: 12)),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          e.createdAt.toString().substring(0, 16),
                          style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
