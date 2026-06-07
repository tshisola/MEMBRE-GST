import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../../app/constants.dart';
import '../../app/theme.dart';
/// Guard for media attendance operators and elevated media roles.
class MediaAttendanceOperatorGuard extends ConsumerWidget {
  const MediaAttendanceOperatorGuard({
    super.key,
    required this.child,
    this.fallback,
  });

  final Widget child;
  final Widget? fallback;

  static const _elevatedRoles = [
    AppConstants.roleAdmin,
    AppConstants.roleMediaLead,
    AppConstants.roleMediaOperator,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final operatorAsync = ref.watch(isMediaAttendanceOperatorProvider);
    final roleAsync = ref.watch(userRoleProvider);

    return operatorAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => fallback ?? _denied(context),
      data: (isOperator) {
        if (isOperator) return child;

        return roleAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => fallback ?? _denied(context),
          data: (role) {
            if (role != null && _elevatedRoles.contains(role)) {
              return child;
            }
            return fallback ?? _denied(context);
          },
        );
      },
    );
  }

  Widget _denied(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_busy, size: 48, color: AppTheme.danger),
            const SizedBox(height: 16),
            Text(
              'Opérateur présence requis',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Seuls les opérateurs présence média de ${AppConstants.city} '
              'peuvent accéder à cette section.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
