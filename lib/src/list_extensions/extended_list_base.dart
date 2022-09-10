import 'dart:collection';

abstract class ExtendedListBase<E> extends ListBase<E>{
  final List<E> l;

  ExtendedListBase(this.l);

  @override
  void set length(int newLength) { l.length = newLength; }
  @override
  int get length => l.length;
  @override
  E operator [](int index) => l[index];
  @override
  void operator []=(int index, E value) { l[index] = value; }

  @override
  void add(E element) {
    l.add(element);
  }

  @override
  void addAll(Iterable<E> iterable) {
    l.addAll(iterable);
  }
}