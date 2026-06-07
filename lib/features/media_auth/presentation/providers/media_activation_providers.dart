import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/activation_request_repository.dart';
import '../../../../shared/models/media_activation_request.dart';

final activationRequestRepositoryProvider = Provider(
  (ref) => ActivationRequestRepository(),
);

final pendingMediaActivationRequestsProvider =
    StreamProvider.autoDispose<List<MediaActivationRequest>>((ref) {
  return ref.watch(activationRequestRepositoryProvider).watchPendingForAdmin();
});

final pendingMediaActivationCountProvider = FutureProvider.autoDispose<int>(
  (ref) => ref.watch(activationRequestRepositoryProvider).countPendingLocal(),
);

final memberActivationStatusProvider = StreamProvider.autoDispose
    .family<MediaActivationRequest?, String>((ref, firebaseUid) {
  return ref
      .watch(activationRequestRepositoryProvider)
      .watchByFirebaseUid(firebaseUid);
});
