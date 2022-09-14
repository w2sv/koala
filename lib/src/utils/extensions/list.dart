import 'map.dart';

extension ListExtensions<E> on List<E> {
  List<E> copy() => [...this];

  Map<E, int> asInvertedMap() => asMap().inverted();
}

extension ListListExtensions<E> on List<List<E>> {
  List<List<E>> copy() => [for (final sub in this) sub.copy()];
}
