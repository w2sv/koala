import 'package:koala/src/utils/map.dart';

import 'extended_list_base.dart';
import '../utils/list.dart';

extension<T> on List<T> {
  Map<T, int> asInvertedMap() => asMap().inverted();
}

/// List keeping tracking of element indices by storing them
/// in a map
class PositionTrackingList<T> extends ExtendedListBase<T> {
  Map<T, int> _object2Index;

  PositionTrackingList(List<T> elements)
      : _object2Index = elements.asInvertedMap(),
        super(elements);

  PositionTrackingList<T> copy() => PositionTrackingList(copy1D(this));

  // *************** overrides *******************

  @override
  void add(T element) {
    super.add(element);
    _object2Index[element] = length - 1;
  }

  @override
  void addAll(Iterable<T> iterable) {
    super.addAll(iterable);
    _object2Index = asInvertedMap();
  }

  @override
  T removeAt(int index) {
    final removedElement = super.removeAt(index);
    _object2Index = asInvertedMap();
    return removedElement;
  }

  @override
  int indexOf(Object? element, [int? start]) => _object2Index[element]!;
}
