import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../../app/theme.dart';

/// Displays the IFCM logo from assets with optional title.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 80,
    this.showTitle = false,
  });

  final double size;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.goldAccent, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppTheme.goldAccent.withValues(alpha: 0.2),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppTheme.surfaceElevated,
                child: Icon(
                  Icons.church,
                  size: size * 0.5,
                  color: AppTheme.goldAccent,
                ),
              ),
            ),
          ),
        ),
        if (showTitle) ...[
          const SizedBox(height: 12),
          Text(
            AppConstants.appName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.goldAccent,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            AppConstants.city,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
        ],
      ],
    );
  }
}
