import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Premium UI kit: gradient buttons, stat cards, section headers, chip bars.
class AdvancedButton extends StatelessWidget {
  const AdvancedButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isExpanded = true,
    this.variant = AdvancedButtonVariant.primary,
    this.height = 48,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isExpanded;
  final AdvancedButtonVariant variant;
  final double height;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    final gradient = _gradientFor(variant);
    final foreground = variant == AdvancedButtonVariant.secondary
        ? AppTheme.goldAccent
        : Colors.black;

    final child = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          height: height,
          decoration: BoxDecoration(
            gradient: enabled ? gradient : null,
            color: enabled ? null : AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
            border: variant == AdvancedButtonVariant.secondary
                ? Border.all(
                    color: enabled ? AppTheme.goldAccent : AppTheme.textSecondary,
                  )
                : null,
            boxShadow: enabled && variant != AdvancedButtonVariant.secondary
                ? [
                    BoxShadow(
                      color: AppTheme.goldAccent.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
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
                  Icon(icon, size: 20, color: enabled ? foreground : AppTheme.textSecondary),
                  const SizedBox(width: 10),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: enabled ? foreground : AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return isExpanded ? SizedBox(width: double.infinity, child: child) : child;
  }

  LinearGradient _gradientFor(AdvancedButtonVariant v) {
    switch (v) {
      case AdvancedButtonVariant.primary:
        return const LinearGradient(
          colors: [AppTheme.goldLight, AppTheme.goldAccent, AppTheme.goldDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case AdvancedButtonVariant.export:
        return const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF43A047), Color(0xFF66BB6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case AdvancedButtonVariant.sync:
        return const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF1976D2), Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case AdvancedButtonVariant.danger:
        return const LinearGradient(
          colors: [Color(0xFFB71C1C), AppTheme.danger, Color(0xFFE57373)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case AdvancedButtonVariant.secondary:
        return const LinearGradient(
          colors: [Colors.transparent, Colors.transparent],
        );
    }
  }
}

enum AdvancedButtonVariant { primary, secondary, export, sync, danger }

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.color,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppTheme.goldAccent;

    return Material(
      color: AppTheme.surfaceContainer,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF333333)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icon != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: accent, size: 20),
                    ),
                  if (icon != null) const Spacer(),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: accent,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class ActionChipBar extends StatelessWidget {
  const ActionChipBar({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(labels.length, (index) {
          final selected = index == selectedIndex;
          return Padding(
            padding: EdgeInsets.only(right: index < labels.length - 1 ? 8 : 0),
            child: FilterChip(
              label: Text(labels[index]),
              selected: selected,
              onSelected: (_) => onSelected(index),
              selectedColor: AppTheme.goldAccent.withValues(alpha: 0.25),
              checkmarkColor: AppTheme.goldAccent,
              labelStyle: TextStyle(
                color: selected ? AppTheme.goldAccent : AppTheme.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: selected ? AppTheme.goldAccent : const Color(0xFF3D3D3D),
              ),
              backgroundColor: AppTheme.surfaceElevated,
            ),
          );
        }),
      ),
    );
  }
}

/// Real-time Firebase connection indicator.
class FirebaseConnectionIndicator extends StatelessWidget {
  const FirebaseConnectionIndicator({
    super.key,
    required this.isConnected,
    this.compact = false,
  });

  final bool isConnected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = isConnected ? AppTheme.success : AppTheme.danger;
    final label = isConnected ? 'Firebase connecté' : 'Hors ligne';

    if (compact) {
      return Tooltip(
        message: label,
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 6,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
