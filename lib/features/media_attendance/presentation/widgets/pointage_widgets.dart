import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../core/members/pointage_member_view.dart';
import '../../../../shared/components/smart_ui_kit.dart';
import '../../../../shared/models/attendance_model.dart';
import '../../../smart/presentation/smart_providers.dart';

/// Badge statut présence.
class PointageStatusBadge extends StatelessWidget {
  const PointageStatusBadge({super.key, required this.status});

  final MediaAttendanceStatus? status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = _resolve();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  (String, Color) _resolve() {
    switch (status) {
      case MediaAttendanceStatus.present:
        return ('À l\'heure', AppTheme.successProd);
      case MediaAttendanceStatus.late:
        return ('Retard', AppTheme.warningProd);
      case MediaAttendanceStatus.excused:
        return ('Excusé', AppTheme.brandBlue);
      case MediaAttendanceStatus.absent:
        return ('Absent', AppTheme.errorProd);
      case null:
        return ('Non pointé', AppTheme.textMuted);
    }
  }
}

/// Badge sync discret.
class AttendanceSyncStatusBadge extends StatelessWidget {
  const AttendanceSyncStatusBadge({super.key, required this.syncStatus});

  final String syncStatus;

  @override
  Widget build(BuildContext context) {
    final isPending = syncStatus == 'pending' || syncStatus == 'local';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isPending
            ? AppTheme.warningProd.withValues(alpha: 0.12)
            : AppTheme.successProd.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isPending ? 'Local' : 'Sync',
        style: TextStyle(
          fontSize: 10,
          color: isPending ? AppTheme.warningProd : AppTheme.successProd,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Compteur pointage.
class PointageCounterCard extends StatelessWidget {
  const PointageCounterCard({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          if (icon != null) Icon(icon, color: color, size: 18),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Filtres chips.
class PointageFilterChips<T> extends StatelessWidget {
  const PointageFilterChips({
    super.key,
    required this.filters,
    required this.selected,
    required this.onSelected,
    required this.labelBuilder,
  });

  final List<T> filters;
  final T selected;
  final ValueChanged<T> onSelected;
  final String Function(T) labelBuilder;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = f == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(labelBuilder(f)),
              selected: isSelected,
              onSelected: (_) => onSelected(f),
              selectedColor: AppTheme.brandOrange.withValues(alpha: 0.25),
              checkmarkColor: AppTheme.brandOrange,
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.brandWhite : AppTheme.textMuted,
                fontSize: 12,
              ),
              backgroundColor: AppTheme.cardSecondary,
              side: BorderSide(
                color: isSelected ? AppTheme.brandOrange : AppTheme.cardSecondary,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Barre recherche pointage.
class PointageSearchBar extends StatelessWidget {
  const PointageSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onScan,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onScan;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: AppTheme.brandWhite),
      decoration: InputDecoration(
        hintText: 'Nom, téléphone, code, QR…',
        hintStyle: const TextStyle(color: AppTheme.textMuted),
        prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
        suffixIcon: onScan != null
            ? IconButton(
                icon: const Icon(Icons.qr_code_scanner, color: AppTheme.brandOrange),
                onPressed: onScan,
              )
            : null,
        filled: true,
        fillColor: AppTheme.cardDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        isDense: true,
      ),
      onChanged: onChanged,
    );
  }
}

/// Bouton action pointage.
class PointageActionButton extends StatelessWidget {
  const PointageActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.compact = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: compact ? 32 : 40,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: compact ? 14 : 18, color: color),
        label: Text(label, style: TextStyle(color: color, fontSize: compact ? 11 : 13)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.withValues(alpha: 0.5)),
          backgroundColor: color.withValues(alpha: 0.08),
          padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12),
        ),
      ),
    );
  }
}

/// Carte membre pointage professionnelle.
class PointageMemberCard extends ConsumerWidget {
  const PointageMemberCard({
    super.key,
    required this.member,
    required this.status,
    this.arrivalTime,
    required this.canPoint,
    required this.onStatusChanged,
    this.onQuickPresent,
    this.onDelete,
    this.showDelete = false,
  });

  final PointageMemberView member;
  final MediaAttendanceStatus? status;
  final String? arrivalTime;
  final bool canPoint;
  final ValueChanged<MediaAttendanceStatus> onStatusChanged;
  final VoidCallback? onQuickPresent;
  final VoidCallback? onDelete;
  final bool showDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoreAsync = ref.watch(memberScoreProvider(member.id));
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: const TextStyle(
                        color: AppTheme.brandWhite,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${member.memberCode} · ${member.phone.isNotEmpty ? member.phone : '—'}',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    ),
                    Text(
                      '${member.departmentName ?? member.departmentId} · ${member.commune}',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    ),
                    scoreAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (score) => Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: MemberScoreBadgeChip(score: score, compact: true),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  PointageStatusBadge(status: status),
                  const SizedBox(height: 6),
                  AttendanceSyncStatusBadge(syncStatus: member.syncStatus),
                  if (member.hasQr)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(Icons.qr_code_2, color: AppTheme.brandBlue, size: 16),
                    ),
                ],
              ),
            ],
          ),
          if (arrivalTime != null) ...[
            const SizedBox(height: 6),
            Text(
              'Arrivée : ${_formatTime(arrivalTime!)}',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
            ),
          ],
          if (canPoint) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                PointageActionButton(
                  label: 'Présent',
                  icon: Icons.check_circle_outline,
                  color: AppTheme.successProd,
                  compact: true,
                  onPressed: onQuickPresent ?? () => onStatusChanged(MediaAttendanceStatus.present),
                ),
                PointageActionButton(
                  label: 'Retard',
                  icon: Icons.schedule,
                  color: AppTheme.warningProd,
                  compact: true,
                  onPressed: () => onStatusChanged(MediaAttendanceStatus.late),
                ),
                PointageActionButton(
                  label: 'Absent',
                  icon: Icons.cancel_outlined,
                  color: AppTheme.errorProd,
                  compact: true,
                  onPressed: () => onStatusChanged(MediaAttendanceStatus.absent),
                ),
                PointageActionButton(
                  label: 'Excusé',
                  icon: Icons.event_busy_outlined,
                  color: AppTheme.brandBlue,
                  compact: true,
                  onPressed: () => onStatusChanged(MediaAttendanceStatus.excused),
                ),
                if (showDelete && onDelete != null)
                  PointageDeleteButton(onPressed: onDelete!),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

/// Bouton supprimer membre (Admin autorisé).
class PointageDeleteButton extends StatelessWidget {
  const PointageDeleteButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return PointageActionButton(
      label: 'Supprimer',
      icon: Icons.delete_outline,
      color: AppTheme.errorProd,
      compact: true,
      onPressed: onPressed,
    );
  }
}

/// État vide pointage.
class PointageEmptyState extends StatelessWidget {
  const PointageEmptyState({super.key, required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.people_outline, color: AppTheme.textMuted, size: 48),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(color: AppTheme.brandWhite, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }
}

/// Accès refusé pointage.
class PointageAccessDeniedView extends StatelessWidget {
  const PointageAccessDeniedView({super.key});

  @override
  Widget build(BuildContext context) {
    return const PointageEmptyState(
      title: 'Accès refusé',
      message: 'Vous n\'êtes pas autorisé à pointer ce département.',
    );
  }
}

/// Bouton scanner QR flottant.
class PointageQrButton extends StatelessWidget {
  const PointageQrButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: AppTheme.brandOrange,
      icon: const Icon(Icons.qr_code_scanner),
      label: const Text('Scanner QR'),
    );
  }
}
