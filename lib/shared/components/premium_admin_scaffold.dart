import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/widgets/app_back_button.dart';
import 'app_drawer.dart';

/// Scaffold premium Admin avec menu latéral — sans supprimer les écrans existants.
class PremiumAdminScaffold extends StatelessWidget {
  const PremiumAdminScaffold({
    super.key,
    required this.currentRoute,
    required this.title,
    required this.body,
    this.actions,
    this.fallbackRoute = '/dashboard',
    this.showDrawer = true,
    this.backgroundColor = AppTheme.premiumBlack,
  });

  final String currentRoute;
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final String fallbackRoute;
  final bool showDrawer;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      drawer: showDrawer ? AppDrawer(currentRoute: currentRoute) : null,
      appBar: AppBar(
        backgroundColor: AppTheme.cardDark,
        leading: showDrawer
            ? null
            : AppBackButton(fallbackRoute: fallbackRoute),
        title: Text(title),
        actions: actions,
      ),
      body: body,
    );
  }
}
