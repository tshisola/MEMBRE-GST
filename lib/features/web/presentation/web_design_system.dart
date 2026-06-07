import 'package:flutter/material.dart';

import '../../../app/theme.dart';

/// Palette et composants UI Web premium — MEDIA LUBUMBASHI.
class WebPremiumTheme {
  WebPremiumTheme._();

  static const premiumBlack = Color(0xFF050505);
  static const cardDark = Color(0xFF111827);
  static const cardSecondary = Color(0xFF1F2937);
  static const brandOrange = Color(0xFFF45A1F);
  static const brandBlue = Color(0xFF0067B1);
  static const mediaGold = Color(0xFFD4AF37);
  static const success = Color(0xFF22C55E);
  static const danger = Color(0xFFEF4444);
  static const brandWhite = Color(0xFFFFFFFF);
  static const textMuted = Color(0xFF9CA3AF);
}

class WebGradientHeader extends StatelessWidget {
  const WebGradientHeader({
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [WebPremiumTheme.cardDark, WebPremiumTheme.premiumBlack],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          bottom: BorderSide(color: WebPremiumTheme.cardSecondary),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: WebPremiumTheme.brandWhite,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: const TextStyle(color: WebPremiumTheme.textMuted),
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

class WebGlassCard extends StatelessWidget {
  const WebGlassCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: WebPremiumTheme.cardDark.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WebPremiumTheme.cardSecondary),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class WebDashboardCard extends StatelessWidget {
  const WebDashboardCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.accent = WebPremiumTheme.brandOrange,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return WebGlassCard(
      child: Row(
        children: [
          if (icon != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accent),
            ),
          if (icon != null) const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: WebPremiumTheme.textMuted)),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    color: WebPremiumTheme.brandWhite,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WebActionButton extends StatelessWidget {
  const WebActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = WebPremiumTheme.brandOrange,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: WebPremiumTheme.brandWhite,
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 18),
      ),
      icon: Icon(icon ?? Icons.arrow_forward),
      label: Text(label),
    );
  }
}

class WebBackButton extends StatelessWidget {
  const WebBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Retour',
      onPressed: onPressed ?? () => Navigator.maybePop(context),
      icon: const Icon(Icons.arrow_back, color: WebPremiumTheme.brandWhite),
    );
  }
}

class WebSearchBar extends StatelessWidget {
  const WebSearchBar({
    super.key,
    required this.controller,
    this.hint = 'Rechercher…',
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search, color: WebPremiumTheme.textMuted),
        filled: true,
        fillColor: WebPremiumTheme.cardSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class WebLoadingSkeleton extends StatelessWidget {
  const WebLoadingSkeleton({super.key, this.lines = 4});

  final int lines;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        lines,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            height: 16,
            width: double.infinity,
            margin: EdgeInsets.only(right: i.isOdd ? 80 : 0),
            decoration: BoxDecoration(
              color: WebPremiumTheme.cardSecondary,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }
}

class WebEmptyState extends StatelessWidget {
  const WebEmptyState({super.key, required this.message, this.action});

  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined, size: 48, color: WebPremiumTheme.textMuted),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: WebPremiumTheme.textMuted)),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

class WebErrorState extends StatelessWidget {
  const WebErrorState({super.key, this.message = 'Veuillez réessayer.', this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return WebEmptyState(
      message: message,
      action: onRetry == null
          ? null
          : WebActionButton(label: 'Réessayer', onPressed: onRetry, icon: Icons.refresh),
    );
  }
}

class AdaptiveGrid extends StatelessWidget {
  const AdaptiveGrid({super.key, required this.children, required this.width});

  final List<Widget> children;
  final double width;

  @override
  Widget build(BuildContext context) {
    final cols = width < 600
        ? 1
        : width < 1024
            ? 2
            : width < 1440
                ? 3
                : 4;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: cols,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: cols == 1 ? 2.4 : 1.8,
      children: children,
    );
  }
}

typedef WebPremiumScaffold = WebGlassCard;
typedef ResponsiveDashboardCards = AdaptiveGrid;
typedef WebFilterBar = WebSearchBar;
typedef WebDataTable = WebGlassCard;
typedef ResponsiveDataTable = WebGlassCard;
