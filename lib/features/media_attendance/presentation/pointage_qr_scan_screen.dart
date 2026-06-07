import 'package:flutter/material.dart';

import 'pointage_qr_scan_screen_stub.dart'
    if (dart.library.io) 'pointage_qr_scan_screen_mobile.dart';

/// Scan QR pointage — natif mobile, saisie manuelle Web.
class PointageQrScanScreen extends StatelessWidget {
  const PointageQrScanScreen({super.key});

  @override
  Widget build(BuildContext context) => const PointageQrScanScreenImpl();
}
