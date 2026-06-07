import 'package:pdf/widgets.dart' as pw;

import 'watermark_logo_service.dart';

/// Filigrane logo centré — opacité 8–12 %, sans fond noir.
class PdfWatermarkService {
  PdfWatermarkService({WatermarkLogoService? logoService})
      : _logo = logoService ?? WatermarkLogoService();

  final WatermarkLogoService _logo;

  Future<pw.Widget> buildCenterWatermark({
    double opacity = 0.10,
    double size = 220,
  }) {
    return _logo.buildWatermark(opacity: opacity, size: size);
  }

  Future<pw.PageTheme> pageTheme({double watermarkOpacity = 0.10}) async {
    final watermark = await buildCenterWatermark(opacity: watermarkOpacity);
    return pw.PageTheme(
      pageFormat: (await _logo.pageThemeWithWatermark()).pageFormat,
      buildBackground: (context) => watermark,
    );
  }
}
