import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/production/alphabetic_sort_service.dart';
import '../../core/production/excel_like_search_service.dart';
import 'premium_states.dart';
import 'production_ui_kit.dart';

export '../../core/production/alphabetic_sort_service.dart';

/// Barre d'outils export PDF / CSV / actualiser pour listes professionnelles.
class ListExportToolbar extends StatelessWidget {
  const ListExportToolbar({
    super.key,
    this.onPdf,
    this.onCsv,
    this.onRefresh,
    this.pdfLoading = false,
    this.csvLoading = false,
    this.refreshLoading = false,
  });

  final VoidCallback? onPdf;
  final VoidCallback? onCsv;
  final VoidCallback? onRefresh;
  final bool pdfLoading;
  final bool csvLoading;
  final bool refreshLoading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _ExportButton(
              label: 'PDF',
              icon: Icons.picture_as_pdf,
              color: AppTheme.successProd,
              loading: pdfLoading,
              onPressed: onPdf,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ExportButton(
              label: 'CSV',
              icon: Icons.table_chart_outlined,
              color: AppTheme.brandBlue,
              loading: csvLoading,
              onPressed: onCsv,
            ),
          ),
          if (onRefresh != null) ...[
            const SizedBox(width: 8),
            IconButton.filled(
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.cardSecondary,
                foregroundColor: AppTheme.brandOrange,
              ),
              tooltip: 'Actualiser',
              onPressed: refreshLoading ? null : onRefresh,
              icon: refreshLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExportButton extends StatelessWidget {
  const _ExportButton({
    required this.label,
    required this.icon,
    required this.color,
    this.onPressed,
    this.loading = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.18),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      onPressed: loading ? null : onPressed,
      icon: loading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          : Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

typedef ExportButton = _ExportButton;

/// Filtres rapides style chips pour listes.
class ListFilterChips extends StatelessWidget {
  const ListFilterChips({
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: List.generate(labels.length, (i) {
          final selected = i == selectedIndex;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(labels[i]),
              selected: selected,
              selectedColor: AppTheme.brandOrange.withValues(alpha: 0.25),
              checkmarkColor: AppTheme.brandOrange,
              labelStyle: TextStyle(
                color: selected ? AppTheme.brandOrange : AppTheme.textMuted,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: selected ? AppTheme.brandOrange : AppTheme.cardSecondary,
              ),
              onSelected: (_) => onSelected(i),
            ),
          );
        }),
      ),
    );
  }
}

/// Alias recherche style Excel (réutilise le composant existant).
typedef ExcelLikeSearchBar = SearchExcelLikeField;

/// En-tête professionnel pour listes (titre, département, date, responsable, total).
class ProfessionalListHeader extends StatelessWidget {
  const ProfessionalListHeader({
    super.key,
    required this.title,
    this.departmentName,
    this.dateLabel,
    this.responsible,
    this.totalCount,
    this.syncLabel,
  });

  final String title;
  final String? departmentName;
  final String? dateLabel;
  final String? responsible;
  final int? totalCount;
  final String? syncLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.brandWhite,
            ),
          ),
          if (departmentName != null) ...[
            const SizedBox(height: 6),
            Text(
              departmentName!,
              style: const TextStyle(color: AppTheme.brandOrange, fontSize: 13),
            ),
          ],
          if (dateLabel != null || responsible != null || totalCount != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Wrap(
                spacing: 16,
                runSpacing: 6,
                children: [
                  if (dateLabel != null)
                    _meta(Icons.calendar_today, dateLabel!),
                  if (responsible != null)
                    _meta(Icons.person_outline, responsible!),
                  if (totalCount != null)
                    _meta(Icons.groups_outlined, '$totalCount membres'),
                  if (syncLabel != null)
                    _meta(Icons.sync, syncLabel!),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _meta(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.textMuted),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
      ],
    );
  }
}

/// Ligne de tableau style Excel pour listes dans l'app.
class AdvancedListTableRow extends StatelessWidget {
  const AdvancedListTableRow({
    super.key,
    required this.index,
    required this.name,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.onDelete,
    this.onSecondaryAction,
    this.secondaryIcon = Icons.person_remove_outlined,
    this.secondaryTooltip,
    this.showDelete = false,
  });

  final int index;
  final String name;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onSecondaryAction;
  final IconData secondaryIcon;
  final String? secondaryTooltip;
  final bool showDelete;

  @override
  Widget build(BuildContext context) {
    final even = index.isEven;
    return Material(
      color: even ? AppTheme.cardDark : AppTheme.cardSecondary.withValues(alpha: 0.5),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: Text(
                  '$index',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: AppTheme.brandWhite,
                        fontWeight: FontWeight.w500,
                      ),
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
              if (trailing != null) trailing!,
              if (onSecondaryAction != null)
                IconButton(
                  icon: Icon(secondaryIcon, color: AppTheme.textMuted),
                  tooltip: secondaryTooltip ?? 'Retirer',
                  onPressed: onSecondaryAction,
                ),
              if (showDelete && onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppTheme.errorProd),
                  tooltip: 'Supprimer membre',
                  onPressed: onDelete,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tableau style Excel avec en-têtes colorés.
class AdvancedListTable extends StatelessWidget {
  const AdvancedListTable({
    super.key,
    required this.headers,
    required this.rows,
    this.emptyMessage = 'Aucun élément',
  });

  final List<String> headers;
  final List<Widget> rows;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return EmptyState(title: emptyMessage, icon: Icons.inbox_outlined);
    }
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          color: AppTheme.brandBlue.withValues(alpha: 0.25),
          child: Row(
            children: headers
                .map(
                  (h) => Expanded(
                    flex: h == headers.first ? 2 : 1,
                    child: Text(
                      h,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.brandWhite,
                        fontSize: 12,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        ...rows,
      ],
    );
  }
}

/// Viewer de liste professionnel — recherche, filtres, tri, export, tableau.
class ProfessionalListViewer<T> extends StatefulWidget {
  const ProfessionalListViewer({
    super.key,
    required this.title,
    required this.items,
    required this.nameOf,
    this.subtitleOf,
    this.departmentName,
    this.dateLabel,
    this.responsible,
    this.filterLabels,
    this.filterOf,
    this.onPdf,
    this.onCsv,
    this.onRefresh,
    this.onItemTap,
    this.onDeleteItem,
    this.onSecondaryItem,
    this.canDeleteItem,
    this.pdfLoading = false,
    this.csvLoading = false,
    this.refreshLoading = false,
    this.syncLabel,
    this.emptyTitle = 'Aucun élément',
    this.emptyMessage,
    this.searchHint = 'Rechercher…',
    this.idOf,
  });

  final String title;
  final List<T> items;
  final String Function(T) nameOf;
  final String Function(T)? subtitleOf;
  final String? departmentName;
  final String? dateLabel;
  final String? responsible;
  final List<String>? filterLabels;
  final bool Function(T, int filterIndex)? filterOf;
  final VoidCallback? onPdf;
  final VoidCallback? onCsv;
  final Future<void> Function()? onRefresh;
  final void Function(T)? onItemTap;
  final void Function(T)? onDeleteItem;
  final void Function(T)? onSecondaryItem;
  final bool Function(T)? canDeleteItem;
  final bool pdfLoading;
  final bool csvLoading;
  final bool refreshLoading;
  final String? syncLabel;
  final String emptyTitle;
  final String? emptyMessage;
  final String searchHint;
  final String Function(T)? idOf;

  @override
  State<ProfessionalListViewer<T>> createState() =>
      _ProfessionalListViewerState<T>();
}

class _ProfessionalListViewerState<T> extends State<ProfessionalListViewer<T>> {
  String _query = '';
  int _filterIndex = 0;

  List<T> get _filtered {
    var list = widget.items;
    if (widget.filterLabels != null &&
        widget.filterOf != null &&
        widget.filterLabels!.isNotEmpty) {
      list = list.where((e) => widget.filterOf!(e, _filterIndex)).toList();
    }
    if (_query.isNotEmpty) {
      list = list
          .where(
            (e) => ExcelLikeSearchService.matches(
              query: _query,
              fields: [
                widget.nameOf(e),
                if (widget.subtitleOf != null) widget.subtitleOf!(e),
              ],
            ),
          )
          .toList();
    }
    return AlphabeticSortService.sortBy(list, widget.nameOf);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProfessionalListHeader(
          title: widget.title,
          departmentName: widget.departmentName,
          dateLabel: widget.dateLabel,
          responsible: widget.responsible,
          totalCount: filtered.length,
          syncLabel: widget.syncLabel,
        ),
        if (widget.onPdf != null || widget.onCsv != null || widget.onRefresh != null)
          ListExportToolbar(
            onPdf: widget.onPdf,
            onCsv: widget.onCsv,
            onRefresh: widget.onRefresh == null
                ? null
                : () async => widget.onRefresh!(),
            pdfLoading: widget.pdfLoading,
            csvLoading: widget.csvLoading,
            refreshLoading: widget.refreshLoading,
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: ExcelLikeSearchBar(
            hint: widget.searchHint,
            onChanged: (q) => setState(() => _query = q),
          ),
        ),
        if (widget.filterLabels != null && widget.filterLabels!.isNotEmpty)
          ListFilterChips(
            labels: widget.filterLabels!,
            selectedIndex: _filterIndex,
            onSelected: (i) => setState(() => _filterIndex = i),
          ),
        Expanded(
          child: filtered.isEmpty
              ? EmptyState(
                  title: widget.emptyTitle,
                  message: widget.emptyMessage,
                  icon: Icons.inbox_outlined,
                )
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final item = filtered[i];
                    final canDel = widget.canDeleteItem?.call(item) ?? false;
                    return AdvancedListTableRow(
                      index: i + 1,
                      name: widget.nameOf(item),
                      subtitle: widget.subtitleOf?.call(item),
                      showDelete: canDel && widget.onDeleteItem != null,
                      onDelete: widget.onDeleteItem == null
                          ? null
                          : () => widget.onDeleteItem!(item),
                      onSecondaryAction: widget.onSecondaryItem == null
                          ? null
                          : () => widget.onSecondaryItem!(item),
                      secondaryTooltip: 'Retirer de la liste',
                      onTap: widget.onItemTap == null
                          ? null
                          : () => widget.onItemTap!(item),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

typedef ProfessionalListTable = AdvancedListTable;
