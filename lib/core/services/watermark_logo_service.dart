import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'lubumbashi_branding_service.dart';

/// Loads IFCM logo and builds PDF watermark widgets (Lubumbashi branding).
class WatermarkLogoService {
  WatermarkLogoService({this.logoAssetPath = LubumbashiBrandingService.logoAssetPath});

  final String logoAssetPath;
  pw.MemoryImage? _cachedLogo;

  Future<pw.MemoryImage> loadLogo() async {
    if (_cachedLogo != null) return _cachedLogo!;
    final data = await rootBundle.load(logoAssetPath);
    final bytes = data.buffer.asUint8List();
    _cachedLogo = pw.MemoryImage(bytes);
    return _cachedLogo!;
  }

  Future<Uint8List> loadLogoBytes() async {
    final data = await rootBundle.load(logoAssetPath);
    return data.buffer.asUint8List();
  }

  Future<pw.Widget> buildHeader({double height = 48}) async {
    final logo = await loadLogo();
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          height: height,
          child: pw.Image(logo, fit: pw.BoxFit.contain),
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'MEDIA LUBUMBASHI',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text(
              LubumbashiBrandingService.mediaDepartmentLabel,
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.Text(
              LubumbashiBrandingService.city,
              style: const pw.TextStyle(fontSize: 9),
            ),
          ],
        ),
      ],
    );
  }

  Future<pw.Widget> buildWatermark({
    double opacity = 0.10,
    double size = 220,
  }) async {
    final logo = await loadLogo();
    return pw.Opacity(
      opacity: opacity,
      child: pw.Center(
        child: pw.SizedBox(
          width: size,
          height: size,
          child: pw.Image(logo, fit: pw.BoxFit.contain),
        ),
      ),
    );
  }

  Future<pw.PageTheme> pageThemeWithWatermark() async {
    final watermark = await buildWatermark();
    return pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      buildBackground: (context) => watermark,
    );
  }

  void clearCache() => _cachedLogo = null;
}
