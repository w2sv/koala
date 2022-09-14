import 'list_base.dart';
import 'extensions/list.dart';

/// List keeping track of element indices by storing them
/// in a map and updating them upon list mutation
class ElementPositionTrackingList<T> extends ListBase<T> {
  Map<T, int> _object2Index;

  ElementPositionTrackingList(List<T> elements)
      : _object2Index = elements.asInvertedMap(),
        super(elements);

  ElementPositionTrackingList<T> copy() =>
      ElementPositionTrackingList(ListExtensions(this).copy());

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
