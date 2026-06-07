/// Tri alphabétique stable pour listes membres et exports.
class AlphabeticSortService {
  AlphabeticSortService._();

  static int compareNames(String a, String b) {
    return a.toLowerCase().trim().compareTo(b.toLowerCase().trim());
  }

  static List<T> sortBy<T>(List<T> items, String Function(T) nameOf) {
    final copy = List<T>.from(items);
    copy.sort((a, b) => compareNames(nameOf(a), nameOf(b)));
    return copy;
  }
}
