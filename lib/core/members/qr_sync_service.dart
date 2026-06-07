import 'member_qr_service.dart';

/// Syncs member QR data after cloud id is assigned (stable qrData update).
class QrSyncService {
  QrSyncService({UniqueQrCodeGenerator? qrGen})
      : _qrGen = qrGen ?? UniqueQrCodeGenerator();

  final UniqueQrCodeGenerator _qrGen;

  String qrDataWithCloudId(String qrData, String cloudId) =>
      _qrGen.updateQrDataWithCloudId(qrData, cloudId);
}
