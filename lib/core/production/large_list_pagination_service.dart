/// Pagination mémoire pour ListView.builder (évite charger 10k lignes).
class LargeListPaginationService<T> {
  LargeListPaginationService({
    required List<T> source,
    this.pageSize = 50,
  })  : _all = List<T>.from(source),
        _visibleCount = pageSize.clamp(1, source.length);

  final List<T> _all;
  final int pageSize;
  int _visibleCount;

  List<T> get visibleItems => _all.take(_visibleCount).toList();

  int get totalCount => _all.length;

  bool get hasMore => _visibleCount < _all.length;

  void loadMore() {
    _visibleCount = (_visibleCount + pageSize).clamp(0, _all.length);
  }

  void reset(List<T> source) {
    _all
      ..clear()
      ..addAll(source);
    _visibleCount = pageSize.clamp(1, _all.length);
  }
}
