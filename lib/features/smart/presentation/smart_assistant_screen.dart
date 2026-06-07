import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/smart/automation/smart_automation_center.dart';
import '../../../core/messaging/user_friendly_message_service.dart';
import '../../../core/smart/smart_action_service.dart';
import '../../../core/smart/smart_auto_fix_service.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../shared/components/app_drawer.dart';
import '../../../shared/components/pop_scope_back_guard.dart';
import '../../../shared/components/smart_ui_kit.dart';
import 'smart_providers.dart';

/// Hub principal — Assistant Intelligent Média.
class SmartAssistantScreen extends ConsumerStatefulWidget {
  const SmartAssistantScreen({super.key});

  @override
  ConsumerState<SmartAssistantScreen> createState() =>
      _SmartAssistantScreenState();
}

class _SmartAssistantScreenState extends ConsumerState<SmartAssistantScreen> {
  bool _fixing = false;
  final _ignored = <String>{};

  Future<void> _refresh() async {
    ref.invalidate(smartAssistantReportProvider);
    final report = await ref.read(smartAssistantReportProvider.future);
    await SmartNotificationService.dispatchReport(report);
  }

  Future<void> _autoFixAll() async {
    setState(() => _fixing = true);
    final result = await SmartAutoFixService().fixAll();
    ref.invalidate(smartAssistantReportProvider);
    ref.invalidate(smartDashboardSnapshotProvider);
    ref.invalidate(pointageVisibilityProvider);
    if (mounted) {
      setState(() => _fixing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(smartAssistantReportProvider);

    return PopScopeBackGuard(
      fallbackRoute: '/dashboard',
      child: Scaffold(
        backgroundColor: AppTheme.premiumBlack,
        drawer: const AppDrawer(currentRoute: '/smart/assistant'),
        appBar: AppBar(
          backgroundColor: AppTheme.cardDark,
          leading: null,
          title: const Text('Assistant Média'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refresh,
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _refresh,
          color: AppTheme.brandOrange,
          child: reportAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(
            child: Text(UserFriendlyMessageService.genericError()),
          ),
          data: (report) {
            final issues =
                report.issues.where((i) => !_ignored.contains(i.id)).toList();
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SmartScoreCard(
                        label: 'Qualité données',
                        score: report.dataQualityScore,
                        icon: Icons.verified_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SmartScoreCard(
                        label: 'Synchronisation',
                        score: report.syncHealthScore,
                        icon: Icons.sync,
                        color: AppTheme.brandBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SmartProgressCard(
                  label: 'Préparation service',
                  percent: report.servicePrepScore,
                ),
                const SizedBox(height: 16),
                if (_fixing)
                  const LinearProgressIndicator()
                else
                  FilledButton.icon(
                    onPressed: _autoFixAll,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.brandOrange,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    icon: const Icon(Icons.auto_fix_high),
                    label: const Text('Corriger automatiquement'),
                  ),
                const SizedBox(height: 20),
                _quickLinks(context),
                const SizedBox(height: 20),
                Text(
                  'Alertes (${issues.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                if (issues.isEmpty)
                  const IntelligentEmptyState(
                    title: 'Aucune alerte',
                    message: 'Tout est en ordre pour le moment.',
                  )
                else
                  ...issues.map(
                    (issue) => SmartAlertCard(
                      issue: issue,
                      onFix: issue.autoFixable
                          ? () async {
                              final r = await SmartActionService()
                                  .autoFixIssue(issue);
                              ref.invalidate(smartAssistantReportProvider);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(r.message)),
                                );
                              }
                            }
                          : null,
                      onDetails: issue.detailRoute != null
                          ? () => context.push(issue.detailRoute!)
                          : null,
                      onIgnore: () => setState(() => _ignored.add(issue.id)),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  'Recommandations',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                ...report.recommendations.map(
                  (r) => SmartRecommendationCard(
                    recommendation: r,
                    onTap: r.route != null ? () => context.push(r.route!) : null,
                  ),
                ),
              ],
            );
          },
        ),
        ),
      ),
    );
  }

  Widget _quickLinks(BuildContext context) {
    final links = [
      ('Pointage', Icons.fact_check, '/smart/pointage-problems'),
      ('Qualité', Icons.analytics, '/smart/data-quality'),
      ('Équipe dimanche', Icons.groups, '/smart/team-planning'),
      ('Alertes présence', Icons.warning_amber, '/smart/attendance-alerts'),
      ('Checklist', Icons.checklist, '/smart/checklist'),
      ('Rapport', Icons.summarize, '/smart/report'),
      ('Dashboard', Icons.dashboard_customize, '/smart/admin-dashboard'),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: links
          .map(
            (l) => ActionChip(
              avatar: Icon(l.$2, size: 16, color: AppTheme.brandOrange),
              label: Text(l.$1),
              onPressed: () => context.push(l.$3),
              backgroundColor: AppTheme.cardDark,
            ),
          )
          .toList(),
    );
  }
}
