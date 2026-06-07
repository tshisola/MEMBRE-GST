import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/constants.dart';
import '../../app/theme.dart';
import '../../core/widgets/app_logo.dart';

/// Main scaffold with drawer navigation for authenticated IFCM screens.
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.showDrawer = true,
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;
  final bool showDrawer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
      ),
      drawer: showDrawer ? _AppDrawer(currentPath: GoRouterState.of(context).uri.path) : null,
      body: child,
    );
  }
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer({required this.currentPath});

  final String currentPath;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: AppTheme.surfaceElevated,
              ),
              child: const AppLogo(size: 72, showTitle: true),
            ),
            _DrawerTile(
              icon: Icons.dashboard_outlined,
              label: 'Tableau de bord',
              route: '/dashboard',
              currentPath: currentPath,
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Média — ${AppConstants.city}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
            ),
            _DrawerTile(
              icon: Icons.hub_outlined,
              label: 'Hub Média',
              route: '/media',
              currentPath: currentPath,
            ),
            _DrawerTile(
              icon: Icons.fact_check_outlined,
              label: 'Présence',
              route: '/media/attendance',
              currentPath: currentPath,
            ),
            _DrawerTile(
              icon: Icons.badge_outlined,
              label: 'Rôles',
              route: '/media/roles',
              currentPath: currentPath,
            ),
            _DrawerTile(
              icon: Icons.list_alt_outlined,
              label: 'Listes',
              route: '/media/lists',
              currentPath: currentPath,
            ),
            _DrawerTile(
              icon: Icons.edit_note_outlined,
              label: 'Listes manuelles',
              route: '/media/lists/manual',
              currentPath: currentPath,
            ),
            _DrawerTile(
              icon: Icons.history,
              label: 'Historique',
              route: '/media/history',
              currentPath: currentPath,
            ),
            const Spacer(),
            const Divider(),
            _DrawerTile(
              icon: Icons.sync,
              label: 'Synchronisation',
              route: '/admin/sync',
              currentPath: currentPath,
            ),
            _DrawerTile(
              icon: Icons.settings_outlined,
              label: 'Paramètres',
              route: '/settings',
              currentPath: currentPath,
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: AppTheme.danger),
              title: const Text('Déconnexion'),
              onTap: () => context.go('/login'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.route,
    required this.currentPath,
  });

  final IconData icon;
  final String label;
  final String route;
  final String currentPath;

  @override
  Widget build(BuildContext context) {
    final selected = currentPath == route || currentPath.startsWith('$route/');

    return ListTile(
      leading: Icon(
        icon,
        color: selected ? AppTheme.goldAccent : AppTheme.textSecondary,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: selected ? AppTheme.goldAccent : AppTheme.textPrimary,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: selected,
      onTap: () {
        Navigator.pop(context);
        context.go(route);
      },
    );
  }
}
