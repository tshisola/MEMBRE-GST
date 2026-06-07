import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dynamic_config_services.dart';
import 'remote_update_applier.dart';
import 'sync_all_cloud_config_service.dart';

final remoteUpdateApplierProvider = Provider<RemoteUpdateApplier>((ref) {
  return RemoteUpdateApplier();
});

final syncAllCloudConfigProvider = Provider<SyncAllCloudConfigService>((ref) {
  return SyncAllCloudConfigService();
});

final dynamicThemeProvider = Provider<DynamicThemeService>((ref) {
  return ref.watch(remoteUpdateApplierProvider).theme;
});

final featureFlagProvider = Provider<DynamicFeatureFlagService>((ref) {
  return ref.watch(remoteUpdateApplierProvider).flags;
});

final remoteTextProvider = Provider<RemoteTextService>((ref) {
  return ref.watch(remoteUpdateApplierProvider).texts;
});
