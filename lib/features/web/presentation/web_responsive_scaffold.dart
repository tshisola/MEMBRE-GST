import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/constants.dart';
import '../../../app/theme.dart';
import '../../../core/auth/role_based_navigation_service.dart';
import '../../../core/providers/session_redirect_provider.dart';
import '../../../core/web/web_responsive_layout_service.dart';
import 'web_design_system.dart';

/// Shell responsive Web — sidebar desktop, compact tablette, bottom nav mobile.
class WebResponsiveScaffold extends ConsumerWidget {
  const WebResponsiveScaffold({
    super.key,
    required this.child,
    required this.path,
  });

  final Widget child;
  final String path;

  static bool shouldWrap(String path) {
    if (!kIsWeb) return false;
    if (path.startsWith('/login') || path.startsWith('/auth/')) return false;
    if (path == '/') return false;
    return true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!shouldWrap(path)) return child;

    final width = MediaQuery.sizeOf(context).width;
    final tier = WebResponsiveLayoutService.tierOf(width);
    final session = ref.watch(sessionForRedirectProvider);
    final role = session?.role;
    final isAdmin = RoleBasedNavigationService.isAdminRole(role);
    final isMember = RoleBasedNavigationService.isMemberAccount(session?.accountType);

    return switch (tier) {
      WebLayoutTier.mobile => WebMobileBottomNav(
          path: path,
          isAdmin: isAdmin,
          isMember: isMember,
          child: child,
        ),
      WebLayoutTier.tablet => WebTabletLayout(
          path: path,
          isAdmin: isAdmin,
          isMember: isMember,
          child: child,
        ),
      _ => WebDesktopLayout(
          path: path,
          isAdmin: isAdmin,
          isMember: isMember,
          child: child,
        ),
    };
  }
}

class WebDesktopLayout extends StatelessWidget {
  const WebDesktopLayout({
    super.key,
    required this.child,
    required this.path,
    required this.isAdmin,
    required this.isMember,
  });

  final Widget child;
  final String path;
  final bool isAdmin;
  final bool isMember;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WebPremiumTheme.premiumBlack,
      body: Row(
        children: [
          WebSidebar(path: path, isAdmin: isAdmin, isMember: isMember, expanded: true),
          Expanded(
            child: Column(
              children: [
                WebTopBar(path: path),
                Expanded(child: _ContentArea(child: child)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WebTabletLayout extends StatelessWidget {
  const WebTabletLayout({
    super.key,
    required this.child,
    required this.path,
    required this.isAdmin,
    required this.isMember,
  });

  final Widget child;
  final String path;
  final bool isAdmin;
  final bool isMember;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WebPremiumTheme.premiumBlack,
      body: Row(
        children: [
          WebSidebar(path: path, isAdmin: isAdmin, isMember: isMember, expanded: false),
          Expanded(
            child: Column(
              children: [
                WebTopBar(path: path, compact: true),
                Expanded(child: _ContentArea(child: child)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WebMobileBottomNav extends StatelessWidget {
  const WebMobileBottomNav({
    super.key,
    required this.child,
    required this.path,
    required this.isAdmin,
    required this.isMember,
  });

  final Widget child;
  final String path;
  final bool isAdmin;
  final bool isMember;

  @override
  Widget build(BuildContext context) {
    final items = _navItems(isAdmin: isAdmin, isMember: isMember);
    return Scaffold(
      backgroundColor: WebPremiumTheme.premiumBlack,
      appBar: AppBar(
        backgroundColor: WebPremiumTheme.cardDark,
        title: Text(AppConstants.appName),
        leading: const WebBackButton(),
      ),
      body: _ContentArea(child: child),
      bottomNavigationBar: NavigationBar(
        backgroundColor: WebPremiumTheme.cardDark,
        selectedIndex: _indexForPath(path, items),
        onDestinationSelected: (i) => context.go(items[i].route),
        destinations: [
          for (final item in items)
            NavigationDestination(icon: Icon(item.icon), label: item.label),
        ],
      ),
    );
  }
}

class WebSidebar extends StatelessWidget {
  const WebSidebar({
    super.key,
    required this.path,
    required this.isAdmin,
    required this.isMember,
    this.expanded = true,
  });

  final String path;
  final bool isAdmin;
  final bool isMember;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final items = _navItems(isAdmin: isAdmin, isMember: isMember);
    return Container(
      width: expanded ? 260 : 72,
      color: WebPremiumTheme.cardDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.all(expanded ? 20 : 12),
            child: Text(
              expanded ? AppConstants.appName : 'ML',
              style: TextStyle(
                color: AppTheme.goldAccent,
                fontWeight: FontWeight.w700,
                fontSize: expanded ? 16 : 14,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                for (final item in items)
                  _SidebarTile(
                    item: item,
                    selected: path.startsWith(item.route),
                    expanded: expanded,
                    onTap: () => context.go(item.route),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WebTopBar extends StatelessWidget {
  const WebTopBar({super.key, required this.path, this.compact = false});

  final String path;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: WebPremiumTheme.cardDark,
        border: Border(bottom: BorderSide(color: WebPremiumTheme.cardSecondary)),
      ),
      child: Row(
        children: [
          if (!compact) const WebBackButton(),
          Expanded(
            child: Text(
              _titleForPath(path),
              style: const TextStyle(
                color: WebPremiumTheme.brandWhite,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (!compact)
            SizedBox(
              width: 280,
              child: WebSearchBar(controller: TextEditingController()),
            ),
        ],
      ),
    );
  }
}

class _ContentArea extends StatelessWidget {
  const _ContentArea({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final maxW = WebResponsiveLayoutService.contentMaxWidth(width);
    return ColoredBox(
      color: WebPremiumTheme.premiumBlack,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxW),
          child: child,
        ),
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({
    required this.item,
    required this.selected,
    required this.expanded,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? WebPremiumTheme.brandOrange : WebPremiumTheme.textMuted;
    return ListTile(
      leading: Icon(item.icon, color: color, size: 22),
      title: expanded
          ? Text(item.label, style: TextStyle(color: color, fontWeight: FontWeight.w600))
          : null,
      selected: selected,
      onTap: onTap,
      dense: !expanded,
    );
  }
}

class _NavItem {
  const _NavItem(this.label, this.icon, this.route);
  final String label;
  final IconData icon;
  final String route;
}

List<_NavItem> _navItems({required bool isAdmin, required bool isMember}) {
  if (isMember) {
    return [
      const _NavItem('Accueil', Icons.home_outlined, '/member/dashboard'),
      const _NavItem('Présence', Icons.event_available_outlined, '/member/attendance'),
      const _NavItem('Profil', Icons.person_outline, '/settings'),
    ];
  }
  final items = <_NavItem>[
    const _NavItem('Tableau de bord', Icons.dashboard_outlined, '/dashboard'),
    const _NavItem('Membres', Icons.groups_outlined, '/members'),
    const _NavItem('Pointage', Icons.fact_check_outlined, '/media/attendance'),
    const _NavItem('Listes Média', Icons.list_alt_outlined, '/media/lists'),
    const _NavItem('Messagerie', Icons.chat_bubble_outline, '/messaging'),
    const _NavItem('Rendez-vous', Icons.event_outlined, '/appointments'),
    const _NavItem('Assistant IA', Icons.auto_awesome, '/ai/assistant'),
    const _NavItem('Synchronisation', Icons.sync_outlined, '/admin/sync'),
    const _NavItem('Paramètres', Icons.settings_outlined, '/settings'),
  ];
  if (isAdmin) {
    items.add(const _NavItem('Diagnostic', Icons.medical_services_outlined, '/admin/diagnostic'));
  }
  return items;
}

int _indexForPath(String path, List<_NavItem> items) {
  for (var i = 0; i < items.length; i++) {
    if (path.startsWith(items[i].route)) return i;
  }
  return 0;
}

String _titleForPath(String path) {
  if (path.startsWith('/members')) return 'Membres';
  if (path.startsWith('/media/attendance')) return 'Pointage';
  if (path.startsWith('/media/lists')) return 'Listes Média';
  if (path.startsWith('/admin/sync')) return 'Synchronisation';
  if (path.startsWith('/admin/diagnostic')) return 'Diagnostic';
  if (path.startsWith('/member')) return 'Espace membre';
  return 'Tableau de bord';
}

typedef WebResponsiveScaffoldAlias = WebResponsiveScaffold;
