import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../models/remote_config_models.dart';

/// Rendu Server-Driven UI — composants autorisés uniquement.
class DynamicScreenRenderer extends StatelessWidget {
  const DynamicScreenRenderer({
    super.key,
    required this.spec,
    this.onAction,
  });

  final RemoteComponentSpec spec;
  final void Function(String actionId)? onAction;

  @override
  Widget build(BuildContext context) {
    return DynamicComponentRenderer(spec: spec, onAction: onAction);
  }
}

class DynamicComponentRenderer extends StatelessWidget {
  const DynamicComponentRenderer({
    super.key,
    required this.spec,
    this.onAction,
  });

  final RemoteComponentSpec spec;
  final void Function(String actionId)? onAction;

  @override
  Widget build(BuildContext context) {
    if (!AllowedRemoteComponentTypes.isAllowed(spec.type)) {
      return const SizedBox.shrink();
    }

    switch (spec.type) {
      case AllowedRemoteComponentTypes.section:
        return _Section(spec: spec, onAction: onAction);
      case AllowedRemoteComponentTypes.card:
        return DynamicCardRenderer(spec: spec, onAction: onAction);
      case AllowedRemoteComponentTypes.actionButton:
        return DynamicActionButtonRenderer(spec: spec, onAction: onAction);
      case AllowedRemoteComponentTypes.banner:
        return _Banner(spec: spec);
      default:
        return const SizedBox.shrink();
    }
  }
}

class DynamicCardRenderer extends StatelessWidget {
  const DynamicCardRenderer({
    super.key,
    required this.spec,
    this.onAction,
  });

  final RemoteComponentSpec spec;
  final void Function(String actionId)? onAction;

  @override
  Widget build(BuildContext context) {
    final title = spec.props['title'] as String? ?? '';
    final subtitle = spec.props['subtitle'] as String?;
    final route = spec.props['route'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: route != null ? const Icon(Icons.arrow_forward_ios, size: 14) : null,
        onTap: route != null ? () => context.push(route) : null,
      ),
    );
  }
}

class DynamicMenuRenderer extends StatelessWidget {
  const DynamicMenuRenderer({
    super.key,
    required this.items,
    this.currentRoute,
  });

  final List<RemoteMenuItem> items;
  final String? currentRoute;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      children: items.map((item) {
        final selected = currentRoute == item.route;
        return ListTile(
          leading: Icon(_iconData(item.icon), color: AppTheme.brandOrange),
          title: Text(item.label),
          selected: selected,
          onTap: () => context.push(item.route),
        );
      }).toList(),
    );
  }

  IconData _iconData(String? name) {
    return switch (name) {
      'sync' => Icons.cloud_sync,
      'update' => Icons.system_update_alt,
      'people' => Icons.people,
      'settings' => Icons.settings,
      _ => Icons.circle_outlined,
    };
  }
}

class DynamicActionButtonRenderer extends StatelessWidget {
  const DynamicActionButtonRenderer({
    super.key,
    required this.spec,
    this.onAction,
  });

  final RemoteComponentSpec spec;
  final void Function(String actionId)? onAction;

  @override
  Widget build(BuildContext context) {
    final label = spec.props['label'] as String? ?? 'Action';
    final actionId = spec.props['actionId'] as String? ?? spec.id;
    final variant = spec.props['variant'] as String? ?? 'primary';

    final color = variant == 'secondary'
        ? AppTheme.brandBlue
        : AppTheme.brandOrange;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: FilledButton.icon(
        onPressed: onAction != null ? () => onAction!(actionId) : null,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          minimumSize: const Size.fromHeight(48),
        ),
        icon: const Icon(Icons.touch_app),
        label: Text(label),
      ),
    );
  }
}

class DynamicListColumnRenderer extends StatelessWidget {
  const DynamicListColumnRenderer({
    super.key,
    required this.columns,
  });

  final List<Map<String, dynamic>> columns;

  @override
  Widget build(BuildContext context) {
    if (columns.isEmpty) return const SizedBox.shrink();
    return Row(
      children: columns.map((col) {
        final label = col['label'] as String? ?? '';
        return Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.textMuted,
              fontSize: 12,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.spec, this.onAction});

  final RemoteComponentSpec spec;
  final void Function(String actionId)? onAction;

  @override
  Widget build(BuildContext context) {
    final title = spec.props['title'] as String? ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 8),
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ...spec.children.map(
          (c) => DynamicComponentRenderer(spec: c, onAction: onAction),
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.spec});

  final RemoteComponentSpec spec;

  @override
  Widget build(BuildContext context) {
    final message = spec.props['message'] as String? ?? '';
    if (message.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.brandBlue.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.brandBlue.withValues(alpha: 0.4)),
      ),
      child: Text(message, style: const TextStyle(color: AppTheme.brandWhite)),
    );
  }
}
