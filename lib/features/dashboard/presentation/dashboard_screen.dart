import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

import '../../../app/constants.dart';
import '../../../app/theme.dart';
import '../../../core/firebase/firebase_initializer.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/components/advanced_design_system.dart';
import '../../../core/advanced/automation/advanced_automation_center.dart';
import '../../../features/admin_realtime/presentation/members_live_provider.dart';
import '../../../shared/components/app_drawer.dart';
import '../../../shared/components/member_sync_ui_kit.dart';
import '../../../shared/components/pop_scope_back_guard.dart';
import '../../../shared/components/premium_ui_kit.dart';
import '../../../shared/components/screen_header.dart';
import 'dashboard_smart_quick_actions.dart';
import '../../media_auth/presentation/providers/media_activation_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({
    super.key,
    this.userRole = AppConstants.roleMember,
    this.userName = 'Membre',
  });

  final String userRole;
  final String userName;

  bool get _canAccessMedia =>
      userRole == AppConstants.roleAdmin ||
      userRole == AppConstants.roleMediaLead ||
      userRole == AppConstants.roleMediaOperator ||
      userRole == AppConstants.roleMember;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConnected = FirebaseInitializer.isInitialized;
    final membersAsync = ref.watch(membersLiveProvider);
    final syncSummaryAsync = ref.watch(memberSyncSummaryProvider);
    final banner = ref.watch(memberSyncBannerProvider);
    final memberCount = membersAsync.valueOrNull?.length ?? 0;
    final pendingSync = syncSummaryAsync.valueOrNull?.pending ?? 0;
    final pendingMediaAsync = ref.watch(pendingMediaActivationCountProvider);
    final pendingMedia = pendingMediaAsync.valueOrNull ?? 0;

    return PopScopeBackGuard(
      confirmExitAtRoot: true,
      rootRoute: '/dashboard',
      fallbackRoute: '/dashboard',
      child: Scaffold(
      backgroundColor: AppTheme.premiumBlack,
      drawer: const AppDrawer(currentRoute: '/dashboard'),
      appBar: AppBar(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Tableau de bord'),
        actions: [
          RefreshButton(
            compact: true,
            onRefresh: () async {
              final r = await ref.read(manualSyncRefreshServiceProvider).refresh();
              bumpMembersRevision(ref);
              return r.message;
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FirebaseConnectionIndicator(
              isConnected: isConnected,
              compact: true,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const _DashboardSmartBootstrap(),
          if (banner != null)
            RealtimeUpdateBanner(
              message: banner,
              onDismiss: () =>
                  ref.read(memberSyncBannerProvider.notifier).state = null,
            ),
          ScreenHeader(
            title: 'Bonjour, $userName',
            subtitle: 'IFCM · ${AppConstants.city}',
            showFirebaseIndicator: true,
            isFirebaseConnected: isConnected,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vue d\'ensemble',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  children: [
                    StatCard(
                      label: 'Membres enregistrés',
                      value: membersAsync.isLoading ? '…' : '$memberCount',
                      icon: Icons.groups_outlined,
                      color: AppTheme.goldAccent,
                    ),
                    StatCard(
                      label: 'Sync en attente',
                      value: '$pendingSync',
                      icon: Icons.sync,
                      color: const Color(0xFF42A5F5),
                    ),
                    if (pendingMedia > 0)
                      StatCard(
                        label: 'Demandes Média en attente',
                        value: '$pendingMedia',
                        icon: Icons.person_add_alt_1,
                        color: AppTheme.brandOrange,
                        onTap: () => context.push('/admin/media-activation-requests'),
                      ),
                    StatCard(
                      label: 'Présents aujourd\'hui',
                      value: '—',
                      icon: Icons.check_circle_outline,
                      color: AppTheme.success,
                    ),
                    StatCard(
                      label: 'Listes actives',
                      value: '—',
                      icon: Icons.list_alt,
                      color: AppTheme.goldLight,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (_canAccessMedia) _buildMediaDepartmentCard(context),
                const SizedBox(height: 16),
                DashboardSmartQuickActions(userRole: userRole),
                const SizedBox(height: 16),
                _buildQuickActions(context),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildMediaDepartmentCard(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/media'),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.goldDark.withValues(alpha: 0.3),
                AppTheme.surfaceContainer,
              ],
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.goldAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.videocam,
                  color: AppTheme.goldAccent,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Département Média',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Pointage, rôles, listes et exports',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.goldAccent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Accès rapide',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _QuickActionChip(
              label: 'Membres',
              icon: Icons.groups_outlined,
              onTap: () => context.push('/members'),
            ),
            _QuickActionChip(
              label: 'Nouveau membre',
              icon: Icons.person_add,
              onTap: () => context.push('/members/create'),
            ),
            _QuickActionChip(
              label: 'Pointage',
              icon: Icons.fact_check_outlined,
              onTap: () => context.push('/media/attendance'),
            ),
            _QuickActionChip(
              label: 'Sync',
              icon: Icons.cloud_sync,
              onTap: () => context.push('/admin/sync'),
            ),
            _QuickActionChip(
              label: 'Assistant IA',
              icon: Icons.psychology_outlined,
              onTap: () => context.push('/smart/assistant'),
            ),
            _QuickActionChip(
              label: 'Commande',
              icon: Icons.hub_outlined,
              onTap: () => context.push('/advanced/command-center'),
            ),
          ],
        ),
      ],
    );
  }
}

class _DashboardSmartBootstrap extends ConsumerStatefulWidget {
  const _DashboardSmartBootstrap();

  @override
  ConsumerState<_DashboardSmartBootstrap> createState() =>
      _DashboardSmartBootstrapState();
}

class _DashboardSmartBootstrapState extends ConsumerState<_DashboardSmartBootstrap> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(AdvancedAutomationCenter.instance.onDashboardOpen());
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: AppTheme.goldAccent),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: AppTheme.surfaceElevated,
      side: const BorderSide(color: Color(0xFF3D3D3D)),
    );
  }
}
