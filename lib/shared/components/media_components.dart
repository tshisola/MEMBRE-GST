import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../shared/models/attendance_model.dart';
import '../../shared/models/member_model.dart';
import '../../shared/models/role_models.dart';

class MediaMemberTile extends StatelessWidget {
  const MediaMemberTile({
    super.key,
    required this.member,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.leading,
  });

  final Member member;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: leading ??
            CircleAvatar(
              backgroundColor: AppTheme.goldAccent.withValues(alpha: 0.2),
              child: Text(
                member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: AppTheme.goldAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        title: Text(
          member.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle ?? '${member.phone} · ${member.commune}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: trailing,
      ),
    );
  }
}

class AttendanceToggle extends StatelessWidget {
  const AttendanceToggle({
    super.key,
    required this.status,
    required this.onChanged,
  });

  final MediaAttendanceStatus status;
  final ValueChanged<MediaAttendanceStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<MediaAttendanceStatus>(
      segments: MediaAttendanceStatus.values
          .map(
            (s) => ButtonSegment<MediaAttendanceStatus>(
              value: s,
              label: Text(
                s.label,
                style: const TextStyle(fontSize: 11),
              ),
              icon: Icon(_iconFor(s), size: 16),
            ),
          )
          .toList(),
      selected: {status},
      onSelectionChanged: (selection) => onChanged(selection.first),
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _colorFor(status).withValues(alpha: 0.2);
          }
          return AppTheme.surfaceElevated;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _colorFor(status);
          }
          return AppTheme.textSecondary;
        }),
      ),
    );
  }

  IconData _iconFor(MediaAttendanceStatus s) {
    switch (s) {
      case MediaAttendanceStatus.present:
        return Icons.check_circle_outline;
      case MediaAttendanceStatus.absent:
        return Icons.cancel_outlined;
      case MediaAttendanceStatus.late:
        return Icons.schedule;
      case MediaAttendanceStatus.excused:
        return Icons.event_busy_outlined;
    }
  }

  Color _colorFor(MediaAttendanceStatus s) {
    switch (s) {
      case MediaAttendanceStatus.present:
        return AppTheme.success;
      case MediaAttendanceStatus.absent:
        return AppTheme.danger;
      case MediaAttendanceStatus.late:
        return AppTheme.goldAccent;
      case MediaAttendanceStatus.excused:
        return AppTheme.info;
    }
  }
}

class RoleBadge extends StatelessWidget {
  const RoleBadge({
    super.key,
    required this.role,
    this.compact = false,
  });

  final MediaRole role;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.goldAccent.withValues(alpha: 0.25),
            AppTheme.goldDark.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.5)),
      ),
      child: Text(
        role.label,
        style: TextStyle(
          color: AppTheme.goldAccent,
          fontSize: compact ? 10 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

enum MediaListType { auto, manual, sunday }

class ListTypeBadge extends StatelessWidget {
  const ListTypeBadge({
    super.key,
    required this.type,
  });

  final MediaListType type;

  @override
  Widget build(BuildContext context) {
    final (label, icon, color) = switch (type) {
      MediaListType.auto => ('Auto', Icons.auto_awesome, const Color(0xFF42A5F5)),
      MediaListType.manual => ('Manuelle', Icons.edit_note, AppTheme.goldAccent),
      MediaListType.sunday => ('Dimanche', Icons.church, AppTheme.success),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
