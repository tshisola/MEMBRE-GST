import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/constants.dart';
import '../../app/theme.dart';
import '../../core/auth/logout_service.dart';
import '../../core/firebase/firebase_initializer.dart';
import '../../core/providers/app_providers.dart';
import '../../features/advanced/presentation/advanced_providers.dart';
import 'advanced_design_system.dart';
import 'premium_ui_kit.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({
    super.key,
    required this.currentRoute,
    this.userName = 'Membre',
    this.userEmail,
  });

  final String currentRoute;
  final String userName;
  final String? userEmail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConnected = FirebaseInitializer.isInitialized;
    final roleAsync = ref.watch(userRoleProvider);
    final isAdminGeneral = roleAsync.valueOrNull == AppConstants.roleAdminGeneral ||
        roleAsync.valueOrNull == AppConstants.roleAdminGeneralOwner;
    final isOwner = roleAsync.valueOrNull == AppConstants.roleAdminGeneralOwner;

    return Drawer(
      child: Column(
        children: [
          _DrawerHeader(
            userName: userName,
            userEmail: userEmail,
            isConnected: isConnected,
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _DrawerSection(title: 'Principal'),
                _DrawerItem(
                  icon: Icons.dashboard_outlined,
                  label: 'Tableau de bord',
                  route: '/dashboard',
                  currentRoute: currentRoute,
                ),
                const Divider(height: 1),
                _DrawerSection(title: 'Département Média'),
                _DrawerItem(
                  icon: Icons.grid_view,
                  label: 'Module Média',
                  route: '/media',
                  currentRoute: currentRoute,
                ),
                _DrawerItem(
                  icon: Icons.fact_check_outlined,
                  label: 'Pointage',
                  route: '/media/attendance',
                  currentRoute: currentRoute,
                ),
                _DrawerItem(
                  icon: Icons.badge_outlined,
                  label: 'Rôles',
                  route: '/media/roles',
                  currentRoute: currentRoute,
                ),
                _DrawerItem(
                  icon: Icons.list_alt,
                  label: 'Listes',
                  route: '/media/lists',
                  currentRoute: currentRoute,
                ),
                _DrawerItem(
                  icon: Icons.edit_note,
                  label: 'Listes manuelles',
                  route: '/media/lists/manual',
                  currentRoute: currentRoute,
                ),
                _DrawerItem(
                  icon: Icons.history,
                  label: 'Historique',
                  route: '/media/history',
                  currentRoute: currentRoute,
                ),
                _DrawerItem(
                  icon: Icons.psychology_outlined,
                  label: 'Assistant Média',
                  route: '/smart/assistant',
                  currentRoute: currentRoute,
                ),
                _DrawerItem(
                  icon: Icons.hub_outlined,
                  label: 'Centre Intelligent Admin',
                  route: '/advanced/command-center',
                  currentRoute: currentRoute,
                ),
                const Divider(height: 1),
                _DrawerSection(title: 'Intelligence'),
                _DrawerItem(
                  icon: Icons.bolt_outlined,
                  label: 'Actions rapides',
                  route: '/advanced/quick-actions',
                  currentRoute: currentRoute,
                ),
                _DrawerItem(
                  icon: Icons.live_tv_outlined,
                  label: 'Activité en direct',
                  route: '/advanced/live',
                  currentRoute: currentRoute,
                ),
                _DrawerItem(
                  icon: Icons.swap_horiz_outlined,
                  label: 'Remplacements',
                  route: '/advanced/replacements',
                  currentRoute: currentRoute,
                ),
                _DrawerItem(
                  icon: Icons.checklist_rtl_outlined,
                  label: 'Checklist service',
                  route: '/smart/checklist',
                  currentRoute: currentRoute,
                ),
                _DrawerItem(
                  icon: Icons.groups_outlined,
                  label: 'Planification Média',
                  route: '/smart/team-planning',
                  currentRoute: currentRoute,
                ),
                _DrawerItem(
                  icon: Icons.warning_amber_outlined,
                  label: 'Pointage — alertes',
                  route: '/smart/pointage-problems',
                  currentRoute: currentRoute,
                ),
                _DrawerItem(
                  icon: Icons.content_copy_outlined,
                  label: 'Doublons',
                  route: '/advanced/duplicates',
                  currentRoute: currentRoute,
                ),
                _DrawerItem(
                  icon: Icons.merge_type,
                  label: 'Fusion doublons',
                  route: '/advanced/duplicate-merge',
                  currentRoute: currentRoute,
                ),
                _DrawerItem(
                  icon: Icons.speed_outlined,
                  label: 'Performance',
                  route: '/advanced/performance',
                  currentRoute: currentRoute,
                ),
                _DrawerItem(
                  icon: Icons.picture_as_pdf_outlined,
                  label: 'Rapports PDF',
                  route: '/advanced/report',
                  currentRoute: currentRoute,
                ),
                _DrawerItem(
                  icon: Icons.history_outlined,
                  label: 'Historique actions',
                  route: '/advanced/action-history',
                  currentRoute: currentRoute,
                ),
                Consumer(
                  builder: (context, ref, _) {
                    final unread = ref.watch(unreadNotificationsCountProvider);
                    final count = unread.valueOrNull ?? 0;
                    return _DrawerItem(
                      icon: Icons.notifications_outlined,
                      label: 'Notifications',
                      route: '/advanced/notifications',
                      currentRoute: currentRoute,
                      badgeCount: count,
                    );
                  },
                ),
                _DrawerItem(
                  icon: Icons.calendar_month_outlined,
                  label: 'Calendrier Média',
                  route: '/advanced/calendar',
                  currentRoute: currentRoute,
                ),
                _DrawerItem(
                  icon: Icons.verified_user_outlined,
                  label: 'Validations',
                  route: '/advanced/approvals',
                  currentRoute: currentRoute,
                ),
                _DrawerItem(
                  icon: Icons.manage_search_outlined,
                  label: 'Audit pro',
                  route: '/advanced/audit',
                  currentRoute: currentRoute,
                ),
                const Divider(height: 1),
                _DrawerSection(title: 'Administration'),
                _DrawerItem(
                  icon: Icons.manage_accounts_outlined,
                  label: 'Gestion comptes',
                  route: '/admin/accounts',
                  currentRoute: currentRoute,
                ),
                _DrawerItem(
                  icon: Icons.groups_outlined,
                  label: 'Registre membres',
                  route: '/members',
                  currentRoute: currentRoute,
                ),
                if (isAdminGeneral)
                  _DrawerItem(
                    icon: Icons.delete_outline,
                    label: 'Corbeille membres',
                    route: '/members/trash',
                    currentRoute: currentRoute,
                  ),
                _DrawerItem(
                  icon: Icons.people_outline,
                  label: 'Comptes membres',
                  route: '/admin/member-accounts',
                  currentRoute: currentRoute,
                ),
                _DrawerItem(
                  icon: Icons.list_alt_outlined,
                  label: 'Listes départements',
                  route: '/departments/lists',
                  currentRoute: currentRoute,
                ),
                _DrawerItem(
                  icon: Icons.cloud_sync_outlined,
                  label: 'Synchronisation',
                  route: '/admin/sync',
                  currentRoute: currentRoute,
                ),
                if (isOwner)
                  _DrawerItem(
                    icon: Icons.system_update_alt,
                    label: 'Mises à jour en ligne',
                    route: '/admin/sync/online-updates',
                    currentRoute: currentRoute,
                  ),
                _DrawerItem(
                  icon: Icons.person_add_alt_1,
                  label: 'Demandes Média (Google)',
                  route: '/admin/media-activation-requests',
                  currentRoute: currentRoute,
                ),
                _DrawerItem(
                  icon: Icons.history,
                  label: 'Historique sécurité',
                  route: '/admin/audit-logs',
                  currentRoute: currentRoute,
                ),
                if (isAdminGeneral)
                  _DrawerItem(
                    icon: Icons.bug_report_outlined,
                    label: 'Diagnostic application',
                    route: '/admin/sync/diagnostic',
                    currentRoute: currentRoute,
                  ),
                _DrawerItem(
                  icon: Icons.settings_outlined,
                  label: 'Paramètres',
                  route: '/settings',
                  currentRoute: currentRoute,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.danger),
            title: const Text('Déconnexion', style: TextStyle(color: AppTheme.danger)),
            onTap: () async {
              Navigator.pop(context);
              await ref.read(logoutServiceProvider).logout(ref);
              if (context.mounted) context.go('/login');
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '${AppConstants.appName} · ${AppConstants.city}',
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({
    required this.userName,
    this.userEmail,
    required this.isConnected,
  });

  final String userName;
  final String? userEmail;
  final bool isConnected;

  @override
  Widget build(BuildContext context) {
    return DrawerHeader(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.goldDark.withValues(alpha: 0.4),
            AppTheme.surfaceContainer,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            children: [
              ClipOval(
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const CircleAvatar(
                    backgroundColor: AppTheme.goldAccent,
                    child: Icon(Icons.church, color: Colors.black),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppConstants.appName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.goldAccent,
                      ),
                    ),
                    Text(
                      AppConstants.city,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              FirebaseConnectionIndicator(isConnected: isConnected, compact: true),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            userName,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          if (userEmail != null)
            Text(
              userEmail!,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}

class _DrawerSection extends StatelessWidget {
  const _DrawerSection({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.currentRoute,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String label;
  final String route;
  final String currentRoute;
  final int badgeCount;

  bool get _isSelected {
    if (route == currentRoute) return true;
    if (route != '/media' && currentRoute.startsWith(route)) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: NotificationBadge(
        count: badgeCount,
        child: Icon(
          icon,
          color: _isSelected ? AppTheme.goldAccent : AppTheme.textSecondary,
        ),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: _isSelected ? AppTheme.goldAccent : AppTheme.textPrimary,
          fontWeight: _isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: _isSelected,
      selectedTileColor: AppTheme.goldAccent.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: () {
        Navigator.pop(context);
        if (currentRoute != route) context.go(route);
      },
    );
  }
}
