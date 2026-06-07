import 'models/smart_models.dart';
import 'pointage_visibility_checker.dart';
import 'data_quality_engine.dart';
import 'sync_intelligence_engine.dart';

/// Corrections automatiques globales.
class SmartAutoFixService {
  SmartAutoFixService({
    PointageAutoRepairService? pointage,
    DataRepairService? data,
    AutoSyncRepairService? sync,
  })  : _pointage = pointage ?? PointageAutoRepairService(),
        _data = data ?? DataRepairService(),
        _sync = sync ?? AutoSyncRepairService();

  final PointageAutoRepairService _pointage;
  final DataRepairService _data;
  final AutoSyncRepairService _sync;

  Future<SmartActionResult> fixAll() async {
    var total = 0;
    final p = await _pointage.repairAll();
    total += p.fixedCount;
    final d = await _data.repairMissingDepartments();
    total += d.fixedCount;
    final s = await _sync.retryFailed();
    total += s;

    return (
      success: total > 0,
      message: total > 0
          ? '$total correction(s) appliquée(s).'
          : 'Aucune correction nécessaire.',
      fixedCount: total,
    );
  }
}
