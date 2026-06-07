import 'dart:async';

/// Recherche style Excel avec debounce pour grandes listes.
class ExcelLikeSearchService {
  ExcelLikeSearchService({this.debounce = const Duration(milliseconds: 320)});

  final Duration debounce;
  Timer? _timer;

  void dispose() => _timer?.cancel();

  void onQueryChanged(String query, void Function(String normalized) onSearch) {
    _timer?.cancel();
    _timer = Timer(debounce, () {
      onSearch(query.trim().toLowerCase());
    });
  }

  static bool matches({
    required String query,
    required Iterable<String> fields,
  }) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    for (final field in fields) {
      if (field.toLowerCase().contains(q)) return true;
    }
    return false;
  }
}
