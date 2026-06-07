import '../../app/constants.dart';

/// Formate l'affichage QR — masque les segments techniques (pending, cloudId).
class QrDisplayFormatter {
  QrDisplayFormatter._();

  /// Texte utilisateur sous le QR — jamais "pending" brut.
  static String displayLabel(String qrData, {required String memberCode}) {
    final parts = qrData.split('|');
    if (parts.length >= 3) {
      return '${parts[0]} · $memberCode · ${AppConstants.city}';
    }
    return memberCode;
  }

  /// Indique si le QR utilise encore l'identifiant local (sync cloud en cours).
  static bool isLocalOnly(String qrData) {
    final parts = qrData.split('|');
    if (parts.length < 5) return true;
    final cloudSegment = parts[4].toLowerCase();
    return cloudSegment == 'pending' || cloudSegment == parts[3].toLowerCase();
  }

  static String syncHint(String qrData) {
    if (isLocalOnly(qrData)) {
      return 'QR actif localement — synchronisation cloud en cours.';
    }
    return 'QR synchronisé avec le cloud.';
  }
}
