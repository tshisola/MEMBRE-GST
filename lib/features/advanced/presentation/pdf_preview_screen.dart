import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../../../app/theme.dart';
import '../../../core/advanced/pdf/pdf_export_controller.dart';
import '../../../core/advanced/pdf/pdf_preview_cache.dart';
import '../../../core/messaging/user_friendly_message_service.dart';
import '../../../core/navigation/deep_link_permission_guard.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../shared/components/advanced_design_system.dart';
import '../../../shared/components/pop_scope_back_guard.dart';

/// Aperçu PDF professionnel avant export.
class PdfPreviewScreen extends ConsumerStatefulWidget {
  const PdfPreviewScreen({super.key, required this.cacheKey});

  final String cacheKey;

  @override
  ConsumerState<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends ConsumerState<PdfPreviewScreen> {
  final _controller = PdfExportController();
  bool _busy = false;

  PdfCachedDocument? get _cached {
    return PdfPreviewCache.instance.documentFor(widget.cacheKey);
  }

  Future<int> _pageCount(Uint8List bytes) async {
    var count = 0;
    try {
      await for (final _ in Printing.raster(bytes, dpi: 72)) {
        count++;
      }
    } catch (_) {
      return 0;
    }
    return count;
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(UserFriendlyMessageService.genericError())),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(localSessionProvider);
    final session = sessionAsync.valueOrNull;
    if (session != null && !PdfAccessGuard.canPreview(session)) {
      return PopScopeBackGuard(
        fallbackRoute: '/dashboard',
        child: Scaffold(
          backgroundColor: AppTheme.premiumBlack,
          appBar: AppBar(
            leading: const AppBackButton(fallbackRoute: '/dashboard'),
            title: const Text('Aperçu PDF'),
          ),
          body: const EmptyStatePremium(
            title: 'Accès non autorisé',
            subtitle: 'Vous n\'êtes pas autorisé à consulter ce document.',
            icon: Icons.lock_outline,
          ),
        ),
      );
    }

    final cached = _cached;
    if (cached == null) {
      return PopScopeBackGuard(
        fallbackRoute: '/advanced/report',
        child: Scaffold(
          backgroundColor: AppTheme.premiumBlack,
          appBar: AppBar(
            leading: const AppBackButton(fallbackRoute: '/advanced/report'),
            title: const Text('Aperçu PDF'),
          ),
          body: const EmptyStatePremium(
            title: 'Document indisponible',
            subtitle: 'Veuillez régénérer le rapport.',
          ),
        ),
      );
    }

    final pagesFuture = _pageCount(cached.bytes);

    return PopScopeBackGuard(
      fallbackRoute: '/advanced/report',
      child: Scaffold(
        backgroundColor: AppTheme.premiumBlack,
        appBar: AppBar(
          leading: const AppBackButton(fallbackRoute: '/advanced/report'),
          title: const Text('Aperçu PDF'),
          actions: [
            if (_busy)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: FutureBuilder<int>(
                future: pagesFuture,
                builder: (context, snap) {
                  final pages = snap.data ?? 0;
                  return PdfPreviewCard(
                    title: cached.title,
                    pageHint: pages > 0
                        ? '$pages page${pages > 1 ? 's' : ''}'
                        : 'Document prêt',
                    generatedAt: cached.generatedAt,
                  );
                },
              ),
            ),
            Expanded(
              child: PdfPreview(
                maxPageWidth: 700,
                build: (_) async => cached.bytes,
                allowPrinting: false,
                allowSharing: false,
                canChangeOrientation: false,
                pdfFileName: cached.title,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  SmartActionButton(
                    label: 'Télécharger',
                    icon: Icons.download_outlined,
                    onPressed: _busy
                        ? null
                        : () => _run(() => _controller.share(widget.cacheKey)),
                  ),
                  SmartActionButton(
                    label: 'Partager',
                    icon: Icons.share_outlined,
                    onPressed: _busy
                        ? null
                        : () => _run(() => _controller.share(widget.cacheKey)),
                  ),
                  SmartActionButton(
                    label: 'Imprimer',
                    icon: Icons.print_outlined,
                    onPressed: _busy
                        ? null
                        : () => _run(() => _controller.print(widget.cacheKey)),
                  ),
                  SmartActionButton(
                    label: 'Régénérer',
                    icon: Icons.refresh,
                    onPressed: _busy ? null : () => context.pop(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PdfPreviewCard extends StatelessWidget {
  const PdfPreviewCard({
    super.key,
    required this.title,
    required this.pageHint,
    required this.generatedAt,
  });

  final String title;
  final String pageHint;
  final DateTime generatedAt;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      borderColor: AppTheme.goldAccent.withValues(alpha: 0.35),
      child: Row(
        children: [
          Icon(Icons.picture_as_pdf_outlined, color: AppTheme.goldAccent, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(pageHint, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                Text(
                  'Généré le ${generatedAt.toString().substring(0, 16)}',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper pour ouvrir l'aperçu depuis n'importe quel export.
Future<void> openPdfPreview(
  BuildContext context, {
  required Uint8List bytes,
  required String title,
}) async {
  final key = PdfExportController().storePreview(bytes: bytes, title: title);
  if (context.mounted) {
    context.push('/advanced/pdf-preview?key=$key');
  }
}
