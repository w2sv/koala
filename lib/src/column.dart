import 'package:collection/collection.dart';

import 'list_extensions/extended_list_base.dart';

typedef Mask = List<bool>;

extension MaskExtensions on Mask {
  Mask operator &(Mask other) =>
      IterableZip([this, other]).map((e) => e.first && e.last).toList();

  Mask operator |(Mask other) =>
      IterableZip([this, other]).map((e) => e.first | e.last).toList();

  Mask operator ^(Mask other) =>
      IterableZip([this, other]).map((e) => e.first ^ e.last).toList();
}

class Column<E> extends ExtendedListBase<E> {
  Column(List<E> records) : super(records);

  Column<T> cast<T>() => Column(super.cast<T>());

  // ************* count *****************

  /// Count number of occurrences of [element] of the column [colName].
  int count(E object) => where((element) => element == object).length;

  /// Count number of occurrences of values, corresponding to the column [colName],
  /// equaling any element contained by [pool].
  int countElementOccurrencesOf(Set<E?> pool) =>
      where((element) => pool.contains(element)).length;

  // ************* null freeing *************

  Column<E> nullFreed({E? replaceWith = null}) =>
      Column<E>(nullFreedIterable(replaceWith: replaceWith).toList());

  Iterable<E> nullFreedIterable({E? replaceWith = null}) => replaceWith == null
      ? where((element) => element != null)
      : map((e) => e ?? replaceWith);

  // ****************** transformation ******************

  List<num> cumSum() => _nullFreedNums().fold(
      [],
      (sums, element) =>
          sums..add(sums.isEmpty ? element : sums.last + element));

  // **************** accumulation ****************

  double mean({bool treatNullsAsZeros = true}) =>
      _nullFreedNums(treatNullsAsZeros: treatNullsAsZeros).average;

  num max() => _nullFreedNums().max;

  num min() => _nullFreedNums().min;

  num sum() => _nullFreedNums().sum;

  Iterable<num> _nullFreedNums({bool treatNullsAsZeros = false}) => cast<num?>()
      .nullFreedIterable(replaceWith: treatNullsAsZeros ? 0.0 : null)
      .cast<num>();

  // ***************** masks *******************

  Mask equals(E reference) =>
      map((element) => element == reference).toList().cast<bool>();

  Mask unequals(E reference) =>
      map((element) => element != reference).toList().cast<bool>();

  Mask isIn(Set<E> pool) =>
      map((element) => pool.contains(element)).toList().cast<bool>();

  Mask isNotIn(Set<E> pool) =>
      map((element) => !pool.contains(element)).toList().cast<bool>();

  Mask toMask(bool Function(E) test) => map(test).toList().cast<bool>();

  // ****************** numerical column masks *********************

  Mask operator <(num reference) =>
      cast<num>().map((element) => element < reference).toList().cast<bool>();

  Mask operator >(num reference) =>
      cast<num>().map((element) => element > reference).toList().cast<bool>();

  Mask operator <=(num reference) =>
      cast<num>().map((element) => element <= reference).toList().cast<bool>();

  Mask operator >=(num reference) =>
      cast<num>().map((element) => element >= reference).toList().cast<bool>();
}
