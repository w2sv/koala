import 'list_base.dart';
import 'extensions/list.dart';

/// List keeping track of element indices by storing them
/// in a map and updating them upon list mutation
class ElementPositionTrackingList<E> extends ListBase<E> {
  Map<E, int> _object2Index;

  ElementPositionTrackingList(List<E> elements)
      : _object2Index = elements.asInvertedMap(),
        super(elements);

  ElementPositionTrackingList<E> copy() =>
      ElementPositionTrackingList(ListExtensions(this).copy());

  // *************** overrides *******************

  @override
  bool contains(Object? element) =>
      _object2Index.containsKey(element);

  @override
  void add(E element) {
    super.add(element);
    _object2Index[element] = length - 1;
  }

  @override
  void addAll(Iterable<E> iterable) {
    super.addAll(iterable);
    _object2Index = asInvertedMap();
  }

  @override
  E removeAt(int index) {
    final removedElement = super.removeAt(index);
    _object2Index = asInvertedMap();
    return removedElement;
  }

  @override
  int indexOf(Object? element, [int? start]) =>
      _object2Index[element]!;
}
