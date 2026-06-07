import 'package:flutter/material.dart';

import 'route_guards.dart';

/// Diagnostic technique — Admin Général uniquement.
class AdminOnlyDiagnosticGuard extends StatelessWidget {
  const AdminOnlyDiagnosticGuard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AdminGeneralRouteGuard(child: child);
  }
}
