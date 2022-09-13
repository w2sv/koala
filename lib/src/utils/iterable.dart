extension IterableExtensions<E> on Iterable<E>{
  List<E> toFixedLengthList() => toList(growable: false);
}