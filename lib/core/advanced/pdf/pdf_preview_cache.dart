import 'dart:typed_data';

/// Cache mémoire pour aperçus PDF — affichage local d'abord.
class PdfPreviewCache {
  PdfPreviewCache._();
  static final PdfPreviewCache instance = PdfPreviewCache._();

  final _store = <String, _CachedPdf>{};

  void put(String key, Uint8List bytes, {String? title}) {
    _store[key] = _CachedPdf(
      bytes: bytes,
      title: title ?? key,
      generatedAt: DateTime.now(),
    );
  }

  _CachedPdf? get(String key) => _store[key];

  Uint8List? bytesFor(String key) => _store[key]?.bytes;

  PdfCachedDocument? documentFor(String key) {
    final item = _store[key];
    if (item == null) return null;
    return PdfCachedDocument(
      bytes: item.bytes,
      title: item.title,
      generatedAt: item.generatedAt,
    );
  }

  void clear(String key) => _store.remove(key);
}

class PdfCachedDocument {
  PdfCachedDocument({
    required this.bytes,
    required this.title,
    required this.generatedAt,
  });

  final Uint8List bytes;
  final String title;
  final DateTime generatedAt;
}

class _CachedPdf {
  _CachedPdf({
    required this.bytes,
    required this.title,
    required this.generatedAt,
  });

  final Uint8List bytes;
  final String title;
  final DateTime generatedAt;
}

typedef PdfPreviewService = PdfPreviewCache;
