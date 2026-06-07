import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/production/excel_like_search_service.dart';

/// Bouton production — orange / bleu / neutre.
class ProfessionalButton extends StatelessWidget {
  const ProfessionalButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.color,
    this.outlined = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final Color? color;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final bg = color ?? AppTheme.brandOrange;
    final enabled = onPressed != null && !isLoading;

    if (outlined) {
      return OutlinedButton.icon(
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: bg,
          side: BorderSide(color: bg),
          minimumSize: const Size.fromHeight(48),
        ),
        icon: _icon(enabled, Colors.white),
        label: Text(label),
      );
    }

    return Material(
      color: enabled ? bg : AppTheme.cardSecondary,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _icon(enabled, AppTheme.brandWhite),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.brandWhite,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _icon(bool enabled, Color c) {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: c),
      );
    }
    if (icon == null) return const SizedBox.shrink();
    return Icon(icon, color: enabled ? c : AppTheme.textMuted, size: 22);
  }
}

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, this.message = 'Mode hors ligne'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.warningProd.withValues(alpha: 0.2),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.cloud_off, color: AppTheme.warningProd, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 12, color: AppTheme.brandWhite),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnlineBanner extends StatelessWidget {
  const OnlineBanner({super.key, this.message = 'Synchronisé'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.successProd.withValues(alpha: 0.15),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            const Icon(Icons.cloud_done, color: AppTheme.successProd, size: 18),
            const SizedBox(width: 8),
            Text(message, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

/// Champ recherche style Excel avec debounce.
class SearchExcelLikeField extends StatefulWidget {
  const SearchExcelLikeField({
    super.key,
    required this.onChanged,
    this.hint = 'Rechercher…',
  });

  final ValueChanged<String> onChanged;
  final String hint;

  @override
  State<SearchExcelLikeField> createState() => _SearchExcelLikeFieldState();
}

class _SearchExcelLikeFieldState extends State<SearchExcelLikeField> {
  final _search = ExcelLikeSearchService();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      style: const TextStyle(color: AppTheme.brandWhite),
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: const Icon(Icons.search, color: AppTheme.goldAccent),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _controller.clear();
                  widget.onChanged('');
                },
              ),
      ),
      onChanged: (v) {
        _search.onQueryChanged(v, widget.onChanged);
      },
    );
  }
}

class ExportButton extends StatelessWidget {
  const ExportButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.picture_as_pdf,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ProfessionalButton(
      label: label,
      onPressed: onPressed,
      icon: icon,
      color: AppTheme.successProd,
    );
  }
}

class DashboardCard extends StatelessWidget {
  const DashboardCard({
    super.key,
    required this.title,
    required this.value,
    this.icon,
    this.color,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.cardDark,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null)
                Icon(icon, color: color ?? AppTheme.goldAccent, size: 28),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color ?? AppTheme.brandWhite,
                ),
              ),
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MemberCard extends StatelessWidget {
  const MemberCard({
    super.key,
    required this.name,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final String name;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.cardDark,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      child: ListTile(
        onTap: onTap,
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: trailing,
      ),
    );
  }
}
