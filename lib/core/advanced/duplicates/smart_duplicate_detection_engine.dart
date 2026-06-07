import 'package:uuid/uuid.dart';

import '../../../features/members/data/local_member_repository.dart';
import '../../members/member_duplicate_detector.dart';
import '../../../shared/models/ifcm_member_record.dart';
import '../models/advanced_models.dart';

/// Détection intelligente des doublons membres.
class SmartDuplicateDetectionEngine {
  SmartDuplicateDetectionEngine({
    LocalMemberRepository? repo,
    MemberDuplicateDetector? detector,
  })  : _repo = repo ?? LocalMemberRepository(),
        _detector = detector ?? MemberDuplicateDetector();

  final LocalMemberRepository _repo;
  final MemberDuplicateDetector _detector;
  final _uuid = Uuid();

  Future<List<DuplicateMatch>> scanAll() async {
    final active = await _repo.listActive();
    final deleted = await _repo.listDeleted();
    final members = [...active, ...deleted];
    final matches = <DuplicateMatch>[];
    final seenPhones = <String, IfcmMemberRecord>{};
    final seenNames = <String, IfcmMemberRecord>{};
    final seenQr = <String, IfcmMemberRecord>{};
    final seenCodes = <String, IfcmMemberRecord>{};

    for (final m in members) {
      if (m.isDeleted) continue;

      final phone = m.phone?.trim() ?? '';
      if (phone.isNotEmpty && seenPhones.containsKey(phone)) {
        matches.add(_match(m, 'Téléphone', phone, seenPhones[phone]!));
      } else if (phone.isNotEmpty) {
        seenPhones[phone] = m;
      }

      final name = m.displayName.toLowerCase();
      if (name.isNotEmpty && seenNames.containsKey(name)) {
        matches.add(_match(m, 'Nom', name, seenNames[name]!));
      } else if (name.isNotEmpty) {
        seenNames[name] = m;
      }

      if (m.qrData.isNotEmpty && seenQr.containsKey(m.qrData)) {
        matches.add(_match(m, 'QR Code', m.qrData, seenQr[m.qrData]!));
      } else if (m.qrData.isNotEmpty) {
        seenQr[m.qrData] = m;
      }

      if (seenCodes.containsKey(m.memberCode)) {
        matches.add(_match(m, 'Code membre', m.memberCode, seenCodes[m.memberCode]!));
      } else {
        seenCodes[m.memberCode] = m;
      }

      if (m.syncStatus == 'local' || m.syncStatus == 'pending') {
        final cloud = await _detector.check(
          phone: m.phone,
          memberCode: m.memberCode,
          fullName: m.displayName,
          localId: m.id,
        );
        if (cloud.hasDuplicate && cloud.existingMember?.id != m.id) {
          matches.add(DuplicateMatch(
            id: _uuid.v4(),
            memberId: m.id,
            memberName: m.displayName,
            matchType: 'Local + Cloud',
            matchValue: cloud.reason ?? 'Doublon détecté',
            confidence: 90,
            suggestedAction: 'Fusionner ou corriger',
          ));
        }
      }
    }
    return matches;
  }

  DuplicateMatch _match(
    IfcmMemberRecord m,
    String type,
    String value,
    IfcmMemberRecord other,
  ) {
    return DuplicateMatch(
      id: _uuid.v4(),
      memberId: other.id,
      memberName: other.displayName,
      matchType: type,
      matchValue: value,
      confidence: 85,
      suggestedAction: 'Fusionner ou corriger',
      secondaryMemberId: m.id,
      secondaryMemberName: m.displayName,
      primaryMemberId: other.id,
      similarityScore: 85,
    );
  }
}

/// Assistant fusion doublons (recommandations — sans suppression auto).
class DuplicateMergeAssistant {
  Future<List<String>> suggestSteps(DuplicateMatch match) async {
    return [
      'Ouvrir le détail de ${match.memberName}.',
      'Vérifier le ${match.matchType} : ${match.matchValue}.',
      'Conserver le profil le plus complet.',
      'Demander validation Admin si fusion définitive.',
    ];
  }
}
