import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/navigation/safe_back_navigation_service.dart';
import '../../core/widgets/app_back_button.dart';

/// Scaffold premium avec retour Android intercepté.
class ProfessionalScaffold extends StatelessWidget {
  const ProfessionalScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.fallbackRoute = '/dashboard',
    this.drawer,
    this.floatingActionButton,
    this.confirmExitAtRoot = false,
    this.rootRoute = '/dashboard',
    this.showBack = true,
    this.bottomNavigationBar,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final String fallbackRoute;
  final Widget? drawer;
  final Widget? floatingActionButton;
  final bool confirmExitAtRoot;
  final String rootRoute;
  final bool showBack;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await SafeBackNavigationService.handleWillPop(
          context,
          fallbackRoute: fallbackRoute,
          confirmExitAtRoot: confirmExitAtRoot,
          rootRoute: rootRoute,
        );
      },
      child: Scaffold(
        backgroundColor: AppTheme.premiumBlack,
        drawer: drawer,
        appBar: ProfessionalAppBar(
          title: title,
          actions: actions,
          fallbackRoute: fallbackRoute,
          showBack: showBack,
        ),
        body: body,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: bottomNavigationBar,
      ),
    );
  }
}

typedef AppScaffold = ProfessionalScaffold;
