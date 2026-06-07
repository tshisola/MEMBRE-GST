import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../app/theme.dart';

/// Scan QR natif — Android / iOS / desktop.
class PointageQrScanScreenImpl extends StatefulWidget {
  const PointageQrScanScreenImpl({super.key});

  @override
  State<PointageQrScanScreenImpl> createState() =>
      _PointageQrScanScreenImplState();
}

class _PointageQrScanScreenImplState extends State<PointageQrScanScreenImpl> {
  bool _handled = false;

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value != null && value.isNotEmpty) {
        _handled = true;
        Navigator.of(context).pop(value);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.premiumBlack,
      appBar: AppBar(
        title: const Text('Scanner QR'),
        backgroundColor: AppTheme.premiumBlack,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(onDetect: _onDetect),
          Positioned(
            bottom: 32,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardDark.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Placez le QR Code du membre dans le cadre.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.brandWhite),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
