import 'list_base.dart';
import 'extensions/list.dart';

/// List keeping track of element indices by storing them
/// in a map and updating them upon list mutation
class ElementPositionTrackingList<E> extends ListBase<E> {
  Map<E, int> _object2Index;

  ElementPositionTrackingList(List<E> elements)
      : _object2Index = elements.asInvertedMap(),
        super(elements);

  void _reassignObject2Index() {
    _object2Index = asInvertedMap();
  }

  // *************** overrides *******************

  @override
  void add(E element) {
    super.add(element);
    _object2Index[element] = length - 1;
  }

  @override
  void addAll(Iterable<E> iterable) {
    super.addAll(iterable);
    _reassignObject2Index();
  }

  @override
  E removeAt(int index) {
    final removedElement = super.removeAt(index);
    _reassignObject2Index();
    return removedElement;
  }

  @override
  int indexOf(Object? element, [int? start]) => _object2Index[element]!;

  /// Forwards to [_object2Index] for faster retrieval
  @override
  bool contains(Object? element) => _object2Index.containsKey(element);
}
