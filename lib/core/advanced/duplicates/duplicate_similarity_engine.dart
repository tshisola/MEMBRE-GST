import '../../../shared/models/ifcm_member_record.dart';
import '../models/advanced_models.dart';

/// Calcule la similarité entre deux fiches membres.
class DuplicateSimilarityEngine {
  DuplicateComparison compare(IfcmMemberRecord a, IfcmMemberRecord b) {
    var score = 0;
    final diffs = <FieldDifference>[];

    if (_norm(a.displayName) == _norm(b.displayName) && a.displayName.isNotEmpty) {
      score += 25;
    } else {
      diffs.add(FieldDifference('Nom', a.displayName, b.displayName));
    }

    final phoneA = a.phone?.trim() ?? '';
    final phoneB = b.phone?.trim() ?? '';
    if (phoneA.isNotEmpty && phoneA == phoneB) {
      score += 25;
    } else if (phoneA.isNotEmpty || phoneB.isNotEmpty) {
      diffs.add(FieldDifference('Téléphone', phoneA, phoneB));
    }

    final emailA = a.email?.trim() ?? '';
    final emailB = b.email?.trim() ?? '';
    if (emailA.isNotEmpty && emailA.toLowerCase() == emailB.toLowerCase()) {
      score += 15;
    } else if (emailA.isNotEmpty || emailB.isNotEmpty) {
      diffs.add(FieldDifference('Email', emailA, emailB));
    }

    if (a.memberCode.isNotEmpty && a.memberCode == b.memberCode) {
      score += 15;
    } else {
      diffs.add(FieldDifference('Code membre', a.memberCode, b.memberCode));
    }

    if (a.qrData.isNotEmpty && a.qrData == b.qrData) {
      score += 10;
    } else if (a.qrData.isNotEmpty || b.qrData.isNotEmpty) {
      diffs.add(FieldDifference('QR Code', _mask(a.qrData), _mask(b.qrData)));
    }

    if (_norm(a.commune) == _norm(b.commune) &&
        _norm(a.displayName) == _norm(b.displayName) &&
        a.displayName.isNotEmpty) {
      score += 10;
    }

    final primary = _pickPrimary(a, b);
    final secondary = primary.id == a.id ? b : a;

    return DuplicateComparison(
      similarityScore: score.clamp(0, 100),
      primaryMemberId: primary.id,
      primaryMemberName: primary.displayName,
      secondaryMemberId: secondary.id,
      secondaryMemberName: secondary.displayName,
      differences: diffs,
    );
  }

  IfcmMemberRecord _pickPrimary(IfcmMemberRecord a, IfcmMemberRecord b) {
    int completeness(IfcmMemberRecord m) {
      var c = 0;
      if (m.phone?.trim().isNotEmpty == true) c++;
      if (m.email?.trim().isNotEmpty == true) c++;
      if (m.qrData.isNotEmpty) c++;
      if (m.departmentId?.isNotEmpty == true) c++;
      if (m.cloudId?.isNotEmpty == true) c++;
      if (m.syncStatus == 'synced') c += 2;
      return c;
    }

    return completeness(a) >= completeness(b) ? a : b;
  }

  String _norm(String v) => v.trim().toLowerCase();
  String _mask(String v) => v.length <= 8 ? v : '…${v.substring(v.length - 6)}';
}

class FieldDifference {
  const FieldDifference(this.label, this.primaryValue, this.secondaryValue);
  final String label;
  final String primaryValue;
  final String secondaryValue;
}

class DuplicateComparison {
  const DuplicateComparison({
    required this.similarityScore,
    required this.primaryMemberId,
    required this.primaryMemberName,
    required this.secondaryMemberId,
    required this.secondaryMemberName,
    required this.differences,
  });

  final int similarityScore;
  final String primaryMemberId;
  final String primaryMemberName;
  final String secondaryMemberId;
  final String secondaryMemberName;
  final List<FieldDifference> differences;
}

typedef SmartDuplicateDetector = DuplicateSimilarityEngine;
