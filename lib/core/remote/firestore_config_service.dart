import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app/constants.dart';
import '../firebase/firebase_initializer.dart';
import '../logging/technical_error_repository.dart';
import 'models/remote_config_models.dart';

/// Lecture / écriture collections Firestore de configuration.
class FirestoreConfigService {
  FirestoreConfigService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  bool get isAvailable => FirebaseInitializer.isInitialized;

  Future<Map<String, dynamic>?> readDoc(String collection, [String docId = 'current']) async {
    if (!isAvailable) return null;
    try {
      final snap = await _firestore.collection(collection).doc(docId).get();
      return snap.data();
    } catch (e, st) {
      TechnicalErrorRepository.record(
        source: 'firestore_config_read',
        error: e,
        stack: st,
      );
      return null;
    }
  }

  Future<bool> writeDoc(
    String collection,
    Map<String, dynamic> data, {
    String docId = 'current',
  }) async {
    if (!isAvailable) return false;
    try {
      await _firestore.collection(collection).doc(docId).set(
        {
          ...data,
          'updatedAt': DateTime.now().toIso8601String(),
        },
        SetOptions(merge: true),
      );
      return true;
    } catch (e, st) {
      TechnicalErrorRepository.record(
        source: 'firestore_config_write',
        error: e,
        stack: st,
      );
      return false;
    }
  }

  Future<RemoteAppConfig> loadAppConfig() async {
    final data = await readDoc(AppConstants.collectionAppConfig);
    return RemoteAppConfig.fromMap(data);
  }

  Future<RemoteThemeConfig> loadTheme() async {
    final data = await readDoc(AppConstants.collectionRemoteTheme);
    return RemoteThemeConfig.fromMap(data);
  }

  Future<Map<String, bool>> loadFeatureFlags() async {
    final data = await readDoc(AppConstants.collectionFeatureFlags);
    if (data == null) return {};
    return data.map((k, v) => MapEntry(k, v == true));
  }

  Future<Map<String, String>> loadTexts() async {
    final data = await readDoc(AppConstants.collectionRemoteTexts);
    if (data == null) return {};
    return data.map((k, v) => MapEntry(k, v?.toString() ?? ''));
  }

  Future<List<RemoteMenuItem>> loadMenus() async {
    final data = await readDoc(AppConstants.collectionRemoteMenus);
    final items = data?['items'] as List?;
    if (items == null) return [];
    return items
        .whereType<Map>()
        .map((e) => RemoteMenuItem.fromMap(Map<String, dynamic>.from(e)))
        .where((m) => m.visible)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  Future<List<RemoteDashboardCard>> loadDashboards() async {
    final data = await readDoc(AppConstants.collectionRemoteDashboards);
    final cards = data?['cards'] as List?;
    if (cards == null) return [];
    return cards
        .whereType<Map>()
        .map((e) => RemoteDashboardCard.fromMap(Map<String, dynamic>.from(e)))
        .where((c) => c.visible)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  Future<Map<String, dynamic>> loadAttendanceRules() async {
    return await readDoc(AppConstants.collectionRemoteAttendanceRules) ?? {};
  }

  Future<Map<String, dynamic>> loadPdfTemplates() async {
    return await readDoc(AppConstants.collectionRemotePdfTemplates) ?? {};
  }

  Future<AppVersionInfo> loadAppVersions() async {
    final data = await readDoc(AppConstants.collectionAppVersions, 'latest');
    return AppVersionInfo.fromMap(data);
  }

  Future<RemoteComponentSpec?> loadScreen(String screenId) async {
    final data = await readDoc(AppConstants.collectionRemoteScreens, screenId);
    if (data == null) return null;
    return RemoteComponentSpec.fromMap(data);
  }
}
