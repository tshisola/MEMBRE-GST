import 'dart:typed_data';

import 'package:printing/printing.dart';

import 'pdf_preview_cache.dart';

/// Contrôle export PDF : aperçu, partage, impression.
class PdfExportController {
  PdfExportController({PdfPreviewCache? cache})
      : _cache = cache ?? PdfPreviewCache.instance;

  final PdfPreviewCache _cache;

  String storePreview({
    required Uint8List bytes,
    required String title,
  }) {
    final key = 'pdf_${DateTime.now().millisecondsSinceEpoch}';
    _cache.put(key, bytes, title: title);
    _cache.put('last_pdf', bytes, title: title);
    return key;
  }

  Future<void> share(String cacheKey, {String? filename}) async {
    final item = _cache.get(cacheKey);
    if (item == null) return;
    await PdfShareService.share(item.bytes, filename: filename ?? item.title);
  }

  Future<void> print(String cacheKey) async {
    final bytes = _cache.bytesFor(cacheKey);
    if (bytes == null) return;
    await PdfPrintService.print(bytes);
  }
}

class PdfShareService {
  static Future<void> share(Uint8List bytes, {String filename = 'media_lubumbashi'}) {
    return Printing.sharePdf(bytes: bytes, filename: '$filename.pdf');
  }
}

class PdfPrintService {
  static Future<void> print(Uint8List bytes, {String name = 'media_lubumbashi'}) {
    return Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: name,
    );
  }
}
