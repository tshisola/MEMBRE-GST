import 'package:flutter/material.dart';

import '../../app/theme.dart';

enum AppButtonVariant { primary, secondary, danger, export }

/// Gradient action button used across IFCM screens.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final colors = _gradientColors();
    final foreground = variant == AppButtonVariant.secondary
        ? AppTheme.goldAccent
        : Colors.black;

    final child = InkWell(
      onTap: isLoading ? null : onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: variant == AppButtonVariant.secondary
              ? Border.all(color: AppTheme.goldAccent)
              : null,
          boxShadow: onPressed == null
              ? null
              : [
                  BoxShadow(
                    color: colors.first.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: foreground,
                  ),
                )
              else if (icon != null) ...[
                Icon(icon, color: foreground, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return expanded ? SizedBox(width: double.infinity, child: child) : child;
  }

  List<Color> _gradientColors() {
    switch (variant) {
      case AppButtonVariant.primary:
        return [AppTheme.goldLight, AppTheme.goldAccent, AppTheme.goldDark];
      case AppButtonVariant.secondary:
        return [AppTheme.surfaceElevated, AppTheme.surfaceContainer];
      case AppButtonVariant.danger:
        return [const Color(0xFFE57373), AppTheme.danger, const Color(0xFFB00020)];
      case AppButtonVariant.export:
        return [const Color(0xFF66BB6A), AppTheme.success, const Color(0xFF2E7D32)];
    }
  }
}
