import 'package:collection/collection.dart';

extension IterableExtensions<E> on Iterable<E> {
  List<E> toFixedLengthList() => toList(growable: false);

  Iterable<E> applyMask(List<bool> mask) =>
      whereIndexed((index, _) => mask[index]);
}

extension IterableIterableExtensions<E> on Iterable<Iterable<E>>{
  List<List<E>> transposed() =>
      IterableZip(this).map((e) => e.toList()).toList();
}
