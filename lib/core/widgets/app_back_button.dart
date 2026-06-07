import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/navigation/safe_back_navigation_service.dart';

/// Bouton retour standard — Dashboard si pas d'historique.
class AppBackButton extends StatelessWidget {
  const AppBackButton({
    super.key,
    this.fallbackRoute = '/dashboard',
    this.color,
  });

  final String fallbackRoute;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back_ios_new, size: 18, color: color),
      tooltip: 'Retour',
      onPressed: () => SafeBackNavigationService.goBack(
        context,
        fallbackRoute: fallbackRoute,
      ),
    );
  }
}

/// AppBar avec retour intégré.
class ProfessionalAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ProfessionalAppBar({
    super.key,
    required this.title,
    this.actions,
    this.fallbackRoute = '/dashboard',
    this.bottom,
    this.showBack = true,
  });

  final String title;
  final List<Widget>? actions;
  final String fallbackRoute;
  final PreferredSizeWidget? bottom;
  final bool showBack;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.cardDark,
      leading: showBack
          ? AppBackButton(fallbackRoute: fallbackRoute)
          : null,
      title: Text(title),
      actions: actions,
      bottom: bottom,
    );
  }
}
