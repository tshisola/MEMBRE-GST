import '../../database/database_helper.dart';
import '../models/advanced_models.dart';

/// Monitoring performance application (Admin).
class PerformanceMonitor {
  PerformanceMonitor._();
  static final PerformanceMonitor instance = PerformanceMonitor._();

  static int? _startupMs;
  static final _queryTimes = <int>[];

  static void markStartupComplete(int ms) => _startupMs = ms;

  static void recordQuery(int ms) {
    _queryTimes.add(ms);
    if (_queryTimes.length > 50) _queryTimes.removeAt(0);
  }

  Future<PerformanceSnapshot> analyze() async {
    var startup = _startupMs ?? 0;
    var avgQuery = 0;
    try {
      startup = _startupMs ?? await AppStartupTimer.estimate();
      avgQuery = _queryTimes.isEmpty
          ? await SlowQueryDetector.measureSample()
          : (_queryTimes.reduce((a, b) => a + b) / _queryTimes.length).round();
    } catch (_) {
      startup = startup == 0 ? 1200 : startup;
      avgQuery = 50;
    }

    var score = 100;
    if (startup > 3000) score -= 20;
    if (startup > 5000) score -= 15;
    if (avgQuery > 200) score -= 15;
    if (avgQuery > 500) score -= 20;

    final recs = <String>[];
    if (startup > 3000) {
      recs.add('Temps de démarrage élevé — fermez les applications en arrière-plan.');
    }
    if (avgQuery > 200) {
      recs.add('Requêtes lentes détectées — synchronisez quand le réseau est stable.');
    }
    if (recs.isEmpty) recs.add('Performance satisfaisante.');

    final level = score >= 85
        ? PerformanceLevel.excellent
        : score >= 70
            ? PerformanceLevel.good
            : score >= 50
                ? PerformanceLevel.fair
                : PerformanceLevel.poor;

    return PerformanceSnapshot(
      score: score.clamp(0, 100),
      startupMs: startup,
      avgQueryMs: avgQuery,
      recommendations: recs,
      level: level,
    );
  }
}

class AppStartupTimer {
  static int? _startedAt;

  static void start() => _startedAt ??= DateTime.now().millisecondsSinceEpoch;

  static int complete() {
    if (_startedAt == null) return 0;
    final ms = DateTime.now().millisecondsSinceEpoch - _startedAt!;
    PerformanceMonitor.markStartupComplete(ms);
    return ms;
  }

  static Future<int> estimate() async {
    final sw = Stopwatch()..start();
    await DatabaseHelper.instance.database;
    sw.stop();
    return sw.elapsedMilliseconds + 800;
  }
}

class SlowQueryDetector {
  static Future<int> measureSample() async {
    final sw = Stopwatch()..start();
    final db = await DatabaseHelper.instance.database;
    await db.rawQuery('SELECT COUNT(*) FROM members');
    sw.stop();
    return sw.elapsedMilliseconds;
  }
}

class MemorySafeLoader {
  static List<T> paginate<T>(List<T> source, {int page = 0, int size = 50}) {
    final start = page * size;
    if (start >= source.length) return [];
    final end = (start + size).clamp(0, source.length);
    return source.sublist(start, end);
  }
}

class LargeListOptimizer {
  static int recommendedPageSize(int total) {
    if (total > 500) return 30;
    if (total > 200) return 50;
    return 100;
  }
}
