import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/widgets/app_back_button.dart';
import 'app_drawer.dart';
import 'premium_admin_scaffold.dart';

/// Design system avancé MEDIA LUBUMBASHI.
class PremiumCard extends StatelessWidget {
  const PremiumCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.cardDark,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor ?? AppTheme.cardSecondary),
          ),
          child: child,
        ),
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  const GlassCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppTheme.cardDark.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.brandBlue.withValues(alpha: 0.25)),
      ),
      child: child,
    );
  }
}

class GradientHeader extends StatelessWidget {
  const GradientHeader({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.brandOrange.withValues(alpha: 0.25),
            AppTheme.brandBlue.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: const TextStyle(color: AppTheme.textMuted)),
          ],
        ],
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class ProgressRing extends StatelessWidget {
  const ProgressRing({super.key, required this.percent, this.size = 72, this.color = AppTheme.brandOrange});

  final double percent;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: (percent / 100).clamp(0, 1),
            strokeWidth: 6,
            color: color,
            backgroundColor: AppTheme.cardSecondary,
          ),
          Text('${percent.round()}%', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        ],
      ),
    );
  }
}

class ReportCard extends StatelessWidget {
  const ReportCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.icon = Icons.picture_as_pdf_outlined,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: AppTheme.brandOrange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppTheme.textMuted),
        ],
      ),
    );
  }
}

class EmptyStatePremium extends StatelessWidget {
  const EmptyStatePremium({super.key, required this.title, this.subtitle, this.icon = Icons.inbox_outlined});

  final String title;
  final String? subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppTheme.textMuted),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textMuted)),
            ],
          ],
        ),
      ),
    );
  }
}

class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({super.key, this.height = 80});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

class QuickActionCard extends StatelessWidget {
  const QuickActionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    this.subtitle,
    this.status,
    this.onTap,
    this.loading = false,
  });

  final String title;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final String? status;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      borderColor: color.withValues(alpha: 0.35),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: loading ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: loading
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: color,
                        ),
                      )
                    : Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
              if (status != null)
                StatusBadge(label: status!, color: color),
              if (!loading)
                Icon(Icons.chevron_right, color: color.withValues(alpha: 0.7)),
            ],
          ),
        ),
      ),
    );
  }
}

class FilterChipGroup extends StatelessWidget {
  const FilterChipGroup({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelected,
  });

  final List<String> labels;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: labels.map((l) {
        final isSel = l == selected;
        return FilterChip(
          label: Text(l),
          selected: isSel,
          onSelected: (_) => onSelected(l),
          backgroundColor: AppTheme.cardSecondary,
          selectedColor: AppTheme.brandOrange.withValues(alpha: 0.25),
          checkmarkColor: AppTheme.brandOrange,
        );
      }).toList(),
    );
  }
}

class SmartActionButton extends StatelessWidget {
  const SmartActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.danger = false,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool danger;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: loading ? null : onPressed,
      icon: loading
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(icon ?? Icons.bolt_outlined),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: danger ? AppTheme.errorProd : AppTheme.brandBlue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

class MemberProgressRing extends ProgressRing {
  const MemberProgressRing({super.key, required super.percent}) : super(color: AppTheme.successProd);
}

class MemberStatusBadge extends StatusBadge {
  MemberStatusBadge.habilite({super.key})
      : super(label: 'Habilité', color: AppTheme.successProd);
  MemberStatusBadge.watch({super.key})
      : super(label: 'À surveiller', color: AppTheme.warningProd);
  MemberStatusBadge.inactive({super.key})
      : super(label: 'Non habilité', color: AppTheme.errorProd);
}

/// Timeline verticale pour l'historique de présence membre.
class MemberTimeline extends StatelessWidget {
  const MemberTimeline({super.key, required this.entries});

  final List<MemberTimelineEntry> entries;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++)
            _TimelineRow(
              entry: entries[i],
              isLast: i == entries.length - 1,
            ),
        ],
      ),
    );
  }
}

class MemberTimelineEntry {
  const MemberTimelineEntry({
    required this.date,
    required this.status,
    required this.sessionType,
  });

  final String date;
  final String status;
  final String sessionType;
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.entry, required this.isLast});

  final MemberTimelineEntry entry;
  final bool isLast;

  Color get _statusColor {
    final s = entry.status.toLowerCase();
    if (s.contains('present') || s.contains('présent')) {
      return AppTheme.successProd;
    }
    if (s.contains('late') || s.contains('retard')) {
      return AppTheme.warningProd;
    }
    if (s.contains('absent')) return AppTheme.errorProd;
    return AppTheme.brandBlue;
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppTheme.cardSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.date,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.brandWhite,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${entry.sessionType} · ${_friendlyStatus(entry.status)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _friendlyStatus(String raw) {
    final s = raw.toLowerCase();
    if (s.contains('present') || s.contains('présent')) return 'Présent';
    if (s.contains('late') || s.contains('retard')) return 'Retard';
    if (s.contains('absent')) return 'Absent';
    return 'Enregistré';
  }
}

/// Carte d'affectation Média ou pastoral.
class MemberAssignmentCard extends StatelessWidget {
  const MemberAssignmentCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.assignment_outlined,
    this.badge,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      borderColor: AppTheme.goldAccent.withValues(alpha: 0.35),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.goldAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.goldAccent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.brandWhite,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          if (badge != null)
            StatusBadge(label: badge!, color: AppTheme.brandOrange),
        ],
      ),
    );
  }
}

/// Badge non lu pour icônes notifications.
class NotificationBadge extends StatelessWidget {
  const NotificationBadge({
    super.key,
    required this.count,
    required this.child,
  });

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (count > 0)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.errorProd,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                count > 99 ? '99+' : '$count',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class ApprovalCard extends PremiumCard {
  ApprovalCard({
    super.key,
    required String title,
    required String subtitle,
    required ApprovalStatusBadge status,
    required VoidCallback? onApprove,
    required VoidCallback? onReject,
  }) : super(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600))),
                  status,
                ],
              ),
              const SizedBox(height: 6),
              Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReject,
                      child: const Text('Refuser'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: onApprove,
                      style: FilledButton.styleFrom(backgroundColor: AppTheme.successProd),
                      child: const Text('Approuver'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
}

class ApprovalStatusBadge extends StatusBadge {
  ApprovalStatusBadge.pending({super.key}) : super(label: 'En attente', color: AppTheme.warningProd);
  ApprovalStatusBadge.approved({super.key}) : super(label: 'Approuvé', color: AppTheme.successProd);
  ApprovalStatusBadge.rejected({super.key}) : super(label: 'Refusé', color: AppTheme.errorProd);
}

class ReplacementSuggestionCard extends PremiumCard {
  ReplacementSuggestionCard({
    super.key,
    required String post,
    required String absent,
    required String replacement,
    required int confidence,
  }) : super(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(post, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text('Absent : $absent', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              const SizedBox(height: 6),
              Text('Remplaçant proposé : $replacement',
                  style: const TextStyle(color: AppTheme.brandBlue)),
              Text('Confiance : $confidence %', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
            ],
          ),
        );
}

class ProfessionalDataTable extends StatelessWidget {
  const ProfessionalDataTable({
    super.key,
    required this.headers,
    required this.rows,
  });

  final List<String> headers;
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(AppTheme.cardSecondary),
        columns: headers.map((h) => DataColumn(label: Text(h))).toList(),
        rows: rows
            .map(
              (r) => DataRow(cells: r.map((c) => DataCell(Text(c))).toList()),
            )
            .toList(),
      ),
    );
  }
}

class AdvancedSearchBar extends StatelessWidget {
  const AdvancedSearchBar({super.key, required this.controller, this.hint = 'Rechercher…'});

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: AppTheme.cardSecondary,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}

/// Alias design premium — réutilise les composants existants sans duplication.
typedef PremiumScaffold = PremiumAdminScaffold;
typedef SmartCard = PremiumCard;
typedef BackButtonPro = AppBackButton;

class PremiumAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PremiumAppBar({
    super.key,
    required this.title,
    this.actions,
    this.fallbackRoute = '/dashboard',
    this.showBack = true,
  });

  final String title;
  final List<Widget>? actions;
  final String fallbackRoute;
  final bool showBack;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.cardDark,
      leading: showBack ? AppBackButton(fallbackRoute: fallbackRoute) : null,
      title: Text(title),
      actions: actions,
    );
  }
}

/// Carte notification premium pour le centre de notifications.
class NotificationCard extends StatelessWidget {
  const NotificationCard({
    super.key,
    required this.title,
    required this.message,
    this.isRead = false,
    this.onOpen,
    this.onDismiss,
    this.severityColor = AppTheme.brandBlue,
  });

  final String title;
  final String message;
  final bool isRead;
  final VoidCallback? onOpen;
  final VoidCallback? onDismiss;
  final Color severityColor;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      borderColor: severityColor.withValues(alpha: isRead ? 0.15 : 0.4),
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notifications_outlined, color: severityColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isRead ? AppTheme.textMuted : AppTheme.textPrimary,
                  ),
                ),
              ),
              if (!isRead) StatusBadge(label: 'Nouveau', color: severityColor),
            ],
          ),
          const SizedBox(height: 6),
          Text(message, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
          if (onOpen != null || onDismiss != null) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                if (onOpen != null)
                  SmartActionButton(label: 'Ouvrir', icon: Icons.open_in_new, onPressed: onOpen),
                if (onDismiss != null)
                  SmartActionButton(label: 'Marquer lu', icon: Icons.done, onPressed: onDismiss),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Écran de chargement lors d'une navigation deep-link.
class DeepLinkLoadingScreen extends StatelessWidget {
  const DeepLinkLoadingScreen({super.key, this.message = 'Ouverture en cours…'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.premiumBlack,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppTheme.brandOrange),
            const SizedBox(height: 16),
            Text(message, style: const TextStyle(color: AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }
}