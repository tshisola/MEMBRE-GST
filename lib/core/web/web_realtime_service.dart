import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/constants.dart';
import '../firebase/firebase_initializer.dart';

/// Écoute Firestore temps réel — membres, pointage, listes, notifications.
class WebFirestoreRealtimeListener {
  WebFirestoreRealtimeListener._();
  static final WebFirestoreRealtimeListener instance =
      WebFirestoreRealtimeListener._();

  final _firestore = FirebaseFirestore.instance;
  final _subs = <StreamSubscription<dynamic>>[];

  bool get isAvailable => kIsWeb && FirebaseInitializer.isInitialized;

  void startAll() {
    if (!isAvailable) return;
    stopAll();
    _subs.add(
      _firestore.collection(AppConstants.collectionMembers).snapshots().listen(
        (_) {},
      ),
    );
    _subs.add(
      _firestore
          .collection(AppConstants.collectionMediaAttendance)
          .snapshots()
          .listen((_) {}),
    );
    _subs.add(
      _firestore.collection(AppConstants.collectionMediaLists).snapshots().listen(
        (_) {},
      ),
    );
    _subs.add(
      _firestore.collection(AppConstants.collectionMessages).snapshots().listen(
        (_) {},
      ),
    );
  }

  void stopAll() {
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    _subs.clear();
  }
}

typedef WebRealtimeService = WebFirestoreRealtimeListener;

final webMemberRealtimeProvider = StreamProvider<List<Map<String, dynamic>>>(
  (ref) {
    if (!kIsWeb || !FirebaseInitializer.isInitialized) {
      return Stream.value([]);
    }
    return FirebaseFirestore.instance
        .collection(AppConstants.collectionMembers)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
  },
);

final webAttendanceRealtimeProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  if (!kIsWeb || !FirebaseInitializer.isInitialized) {
    return Stream.value([]);
  }
  return FirebaseFirestore.instance
      .collection(AppConstants.collectionMediaAttendance)
      .snapshots()
      .map((s) => s.docs.map((d) => d.data()).toList());
});

final webListsRealtimeProvider = StreamProvider<List<Map<String, dynamic>>>(
  (ref) {
    if (!kIsWeb || !FirebaseInitializer.isInitialized) {
      return Stream.value([]);
    }
    return FirebaseFirestore.instance
        .collection(AppConstants.collectionMediaLists)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
  },
);

final webNotificationsRealtimeProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  if (!kIsWeb || !FirebaseInitializer.isInitialized) {
    return Stream.value([]);
  }
  return FirebaseFirestore.instance
      .collection(AppConstants.collectionMessages)
      .snapshots()
      .map((s) => s.docs.map((d) => d.data()).toList());
});

typedef WebMemberRealtimeProvider = StreamProvider<List<Map<String, dynamic>>>;
typedef WebAttendanceRealtimeProvider =
    StreamProvider<List<Map<String, dynamic>>>;
typedef WebListsRealtimeProvider = StreamProvider<List<Map<String, dynamic>>>;
typedef WebNotificationsRealtimeProvider =
    StreamProvider<List<Map<String, dynamic>>>;
