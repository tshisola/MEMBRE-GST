import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:typed_data';

import '../../../app/theme.dart';
import '../../../core/messaging/user_friendly_message_service.dart';
import '../../../core/smart/checklist/media_service_checklist.dart';
import '../../../core/smart/pointage_visibility_checker.dart';
import '../../../core/advanced/notifications/push_notification_service.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../shared/components/app_drawer.dart';
import '../../../shared/components/pop_scope_back_guard.dart';
import '../../../shared/components/smart_ui_kit.dart';
import '../../../core/advanced/pdf/smart_pdf_report_service.dart';
import '../../advanced/presentation/advanced_providers.dart';
import '../../advanced/presentation/pdf_preview_screen.dart';
import 'smart_providers.dart';

/// Problèmes de visibilité au pointage.
class PointageProblemsScreen extends ConsumerStatefulWidget {
  const PointageProblemsScreen({super.key});

  @override
  ConsumerState<PointageProblemsScreen> createState() =>
      _PointageProblemsScreenState();
}

class _PointageProblemsScreenState extends ConsumerState<PointageProblemsScreen> {
  bool _repairing = false;

  Future<void> _repairAll() async {
    setState(() => _repairing = true);
    final result = await PointageAutoRepairService().repairAll();
    await PointageCacheRefresher().refresh();
    ref.invalidate(pointageVisibilityProvider);
    ref.invalidate(smartAssistantReportProvider);
    if (mounted) {
      setState(() => _repairing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(pointageVisibilityProvider);

    return PopScopeBackGuard(
      fallbackRoute: '/smart/assistant',
      child: Scaffold(
        backgroundColor: AppTheme.premiumBlack,
        appBar: AppBar(
          backgroundColor: AppTheme.cardDark,
          leading: const AppBackButton(fallbackRoute: '/smart/assistant'),
          title: const Text('Problèmes pointage'),
        ),
        body: reportAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) =>
              const Center(child: Text('Analyse indisponible pour le moment.')),
          data: (report) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SmartDashboardGrid(
                  children: [
                    SmartScoreCard(
                      label: 'Membres actifs',
                      score: report.activeCount,
                      icon: Icons.groups,
                      showPercent: false,
                    ),
                    SmartScoreCard(
                      label: 'Visibles pointage',
                      score: report.visibleCount,
                      icon: Icons.visibility,
                      color: AppTheme.successProd,
                      showPercent: false,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _repairing ? null : _repairAll,
                  style: FilledButton.styleFrom(backgroundColor: AppTheme.brandOrange),
                  icon: _repairing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_fix_high),
                  label: const Text('Corriger tous les membres invisibles'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    await PointageCacheRefresher().refresh();
                    ref.invalidate(pointageVisibilityProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cache pointage actualisé.')),
                      );
                    }
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Relancer cache pointage'),
                ),
                const SizedBox(height: 16),
                if (report.invisibleMembers.isEmpty)
                  const IntelligentEmptyState(
                    title: 'Tous les membres actifs sont visibles',
                  )
                else
                  ...report.invisibleMembers.map(
                    (m) => Card(
                      color: AppTheme.cardDark,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(m.name),
                        subtitle: Text(m.reason),
                        trailing: m.repairable
                            ? IconButton(
                                icon: const Icon(Icons.build_circle_outlined),
                                color: AppTheme.brandOrange,
                                onPressed: () async {
                                  await PointageAutoRepairService()
                                      .repairMember(m.memberId);
                                  ref.invalidate(pointageVisibilityProvider);
                                },
                              )
                            : null,
                        onTap: () => context.push('/members/${m.memberId}'),
                      ),
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

/// Qualité des données — dashboard.
class DataQualityDashboardScreen extends ConsumerWidget {
  const DataQualityDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qualityAsync = ref.watch(dataQualityReportProvider);

    return PopScopeBackGuard(
      fallbackRoute: '/smart/assistant',
      child: Scaffold(
        backgroundColor: AppTheme.premiumBlack,
        appBar: AppBar(
          backgroundColor: AppTheme.cardDark,
          leading: const AppBackButton(fallbackRoute: '/smart/assistant'),
          title: const Text('Qualité des données'),
        ),
        body: qualityAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) =>
              const Center(child: Text('Analyse indisponible pour le moment.')),
          data: (q) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SmartScoreCard(
                label: 'Score qualité données',
                score: q.score,
                icon: Icons.analytics,
              ),
              const SizedBox(height: 16),
              _statTile('Doublons téléphone', q.duplicatePhoneCount),
              _statTile('QR Code manquants', q.missingQrCount),
              _statTile('Téléphones manquants', q.missingPhoneCount),
              _statTile('Départements manquants', q.missingDepartmentCount),
              const SizedBox(height: 16),
              ...q.issues.map((i) => SmartAlertCard(issue: i)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statTile(String label, int count) {
    return ListTile(
      tileColor: AppTheme.cardDark,
      title: Text(label),
      trailing: Text('$count', style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

/// Planification intelligente équipe dimanche.
class SmartTeamPlanningScreen extends ConsumerStatefulWidget {
  const SmartTeamPlanningScreen({super.key});

  @override
  ConsumerState<SmartTeamPlanningScreen> createState() =>
      _SmartTeamPlanningScreenState();
}

class _SmartTeamPlanningScreenState extends ConsumerState<SmartTeamPlanningScreen> {
  bool _generating = false;

  @override
  Widget build(BuildContext context) {
    final planAsync = ref.watch(sundayTeamPlanProvider);

    return PopScopeBackGuard(
      fallbackRoute: '/smart/assistant',
      child: Scaffold(
        backgroundColor: AppTheme.premiumBlack,
        appBar: AppBar(
          backgroundColor: AppTheme.cardDark,
          leading: const AppBackButton(fallbackRoute: '/smart/assistant'),
          title: const Text('Planification intelligente'),
        ),
        body: planAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) =>
              const Center(child: Text('Planification indisponible.')),
          data: (plan) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              FilledButton.icon(
                onPressed: _generating
                    ? null
                    : () async {
                        setState(() => _generating = true);
                        ref.invalidate(sundayTeamPlanProvider);
                        await ref.read(sundayTeamPlanProvider.future);
                        if (mounted) setState(() => _generating = false);
                      },
                style: FilledButton.styleFrom(backgroundColor: AppTheme.brandBlue),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Générer équipe'),
              ),
              const SizedBox(height: 16),
              ...plan.posts.map((p) => RotationSuggestionCard(post: p)),
              ...plan.notes.map(
                (n) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(n, style: const TextStyle(color: AppTheme.textMuted)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Alertes présence — membres à risque.
class AttendanceAlertsScreen extends ConsumerWidget {
  const AttendanceAlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final risksAsync = ref.watch(attendanceRisksProvider);

    return PopScopeBackGuard(
      fallbackRoute: '/smart/assistant',
      child: Scaffold(
        backgroundColor: AppTheme.premiumBlack,
        appBar: AppBar(
          backgroundColor: AppTheme.cardDark,
          leading: const AppBackButton(fallbackRoute: '/smart/assistant'),
          title: const Text('Alertes présence'),
        ),
        body: risksAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text('Analyse indisponible.')),
          data: (risks) {
            if (risks.isEmpty) {
              return const IntelligentEmptyState(
                title: 'Aucun membre à risque identifié',
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: risks.length,
              itemBuilder: (_, i) {
                final r = risks[i];
                return Card(
                  color: AppTheme.cardDark,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      r.riskType == 'retard' ? Icons.schedule : Icons.person_off,
                      color: AppTheme.brandOrange,
                    ),
                    title: Text(r.name),
                    subtitle: Text('${r.reason} · Risque ${r.riskLevel}%'),
                    onTap: () => context.push('/members/${r.memberId}'),
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

/// Checklist avant service.
class ServiceChecklistScreen extends ConsumerStatefulWidget {
  const ServiceChecklistScreen({super.key});

  @override
  ConsumerState<ServiceChecklistScreen> createState() =>
      _ServiceChecklistScreenState();
}

class _ServiceChecklistScreenState extends ConsumerState<ServiceChecklistScreen> {
  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(serviceChecklistProvider);

    return PopScopeBackGuard(
      fallbackRoute: '/smart/assistant',
      child: Scaffold(
        backgroundColor: AppTheme.premiumBlack,
        drawer: const AppDrawer(currentRoute: '/smart/checklist'),
        appBar: AppBar(
          backgroundColor: AppTheme.cardDark,
          leading: null,
          title: const Text('Checklist avant service'),
        ),
        body: itemsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(
            child: Text(UserFriendlyMessageService.genericError()),
          ),
          data: (items) {
            final done = items.where((i) => i.done).length;
            final pct = items.isEmpty ? 0 : ((done / items.length) * 100).round();
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SmartProgressCard(label: 'Préparation service', percent: pct),
                const SizedBox(height: 16),
                ...items.map(
                  (item) => CheckboxListTile(
                    value: item.done,
                    title: Text(item.label),
                    activeColor: AppTheme.brandOrange,
                    tileColor: AppTheme.cardDark,
                    onChanged: (v) async {
                      final updated = items
                          .map(
                            (i) => i.id == item.id
                                ? i.copyWith(done: v ?? false)
                                : i,
                          )
                          .toList();
                      await MediaServiceChecklist().save(updated);
                      ref.invalidate(serviceChecklistProvider);
                      ref.invalidate(smartAssistantReportProvider);
                      final pct = updated.isEmpty
                          ? 0
                          : ((updated.where((i) => i.done).length / updated.length) * 100)
                              .round();
                      if (pct < 100) {
                        await PushNotificationService.instance.rules
                            .onChecklistIncomplete(pct);
                      }
                    },
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

/// Rapport après activité.
class SmartReportDashboardScreen extends ConsumerStatefulWidget {
  const SmartReportDashboardScreen({super.key});

  @override
  ConsumerState<SmartReportDashboardScreen> createState() =>
      _SmartReportDashboardScreenState();
}

class _SmartReportDashboardScreenState extends ConsumerState<SmartReportDashboardScreen> {
  bool _exporting = false;

  Future<void> _exportPdf() async {
    setState(() => _exporting = true);
    try {
      final pdf = ref.read(smartPdfReportServiceProvider);
      final doc = await pdf.buildReport(SmartReportType.mediaIntelligence);
      final bytes = Uint8List.fromList(await doc.save());
      if (!mounted) return;
      await openPdfPreview(
        context,
        bytes: bytes,
        title: 'Rapport intelligent Média',
      );
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
    final reportAsync = ref.watch(postServiceReportProvider);

    return PopScopeBackGuard(
      fallbackRoute: '/smart/assistant',
      child: Scaffold(
        backgroundColor: AppTheme.premiumBlack,
        appBar: AppBar(
          backgroundColor: AppTheme.cardDark,
          leading: const AppBackButton(fallbackRoute: '/smart/assistant'),
          title: const Text('Rapport intelligent'),
          actions: [
            IconButton(
              icon: _exporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf_outlined),
              tooltip: 'Exporter PDF',
              onPressed: _exporting ? null : _exportPdf,
            ),
          ],
        ),
        body: reportAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text('Rapport indisponible.')),
          data: (r) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SmartScoreCard(
                label: 'Score du service',
                score: r.serviceScore,
                icon: Icons.star_outline,
                color: AppTheme.goldAccent,
              ),
              const SizedBox(height: 16),
              _row('Présents', r.presentCount),
              _row('Absents', r.absentCount),
              _row('Retardataires', r.lateCount),
              _row('À l\'heure', r.onTimeCount),
              _row('Postes couverts', r.coveredPosts),
              _row('Postes non couverts', r.uncoveredPosts),
              const SizedBox(height: 16),
              const Text('Recommandations',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...r.recommendations.map(
                (rec) => ListTile(
                  leading: const Icon(Icons.tips_and_updates_outlined),
                  title: Text(rec),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, int value) {
    return ListTile(
      tileColor: AppTheme.cardDark,
      title: Text(label),
      trailing: Text('$value'),
    );
  }
}

/// Dashboard Admin intelligent.
class SmartAdminDashboardScreen extends ConsumerWidget {
  const SmartAdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapAsync = ref.watch(smartDashboardSnapshotProvider);

    return PopScopeBackGuard(
      fallbackRoute: '/smart/assistant',
      child: Scaffold(
        backgroundColor: AppTheme.premiumBlack,
        appBar: AppBar(
          backgroundColor: AppTheme.cardDark,
          leading: const AppBackButton(fallbackRoute: '/smart/assistant'),
          title: const Text('Dashboard intelligent'),
        ),
        body: snapAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text('Dashboard indisponible.')),
          data: (s) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SmartDashboardGrid(
                children: [
                  SmartScoreCard(
                    label: 'Qualité données',
                    score: s.dataQualityScore,
                  ),
                  SmartScoreCard(
                    label: 'Synchronisation',
                    score: s.syncScore,
                    color: AppTheme.brandBlue,
                  ),
                  SmartScoreCard(
                    label: 'Préparation',
                    score: s.prepScore,
                    color: AppTheme.brandOrange,
                  ),
                  SmartScoreCard(
                    label: 'Membres actifs',
                    score: s.activeMembers,
                    icon: Icons.groups,
                    showPercent: false,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _tile('Visibles au pointage', s.pointageVisible),
              _tile('Invisibles au pointage', s.pointageInvisible,
                  onTap: () => context.push('/smart/pointage-problems')),
              _tile('Sync en attente', s.pendingSync),
              _tile('QR manquants', s.missingQr),
              _tile('Alertes critiques', s.criticalAlerts),
              _tile('Retardataires fréquents', s.frequentLate),
              _tile('Absents fréquents', s.frequentAbsent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(String label, int value, {VoidCallback? onTap}) {
    return Card(
      color: AppTheme.cardDark,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        title: Text(label),
        trailing: Text('$value', style: const TextStyle(fontWeight: FontWeight.bold)),
        onTap: onTap,
      ),
    );
  }
}