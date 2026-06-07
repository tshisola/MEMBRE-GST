import 'dart:async';

typedef SearchCallback = void Function(String query);

/// Recherche avec debounce pour le pointage.
class DebouncedSearchService {
  DebouncedSearchService({this.delay = const Duration(milliseconds: 280)});

  final Duration delay;
  Timer? _timer;
  String _lastQuery = '';

  String get lastQuery => _lastQuery;

  void search(String query, SearchCallback onResults) {
    _timer?.cancel();
    _timer = Timer(delay, () {
      _lastQuery = query;
      onResults(query);
    });
  }

  void dispose() {
    _timer?.cancel();
  }
}
