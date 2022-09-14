import 'package:collection/collection.dart';

import 'utils/list_base.dart';

class Column<E> extends ListBase<E> {
  Column(List<E> records) : super(records);

  /// Get a casted [Column].
  Column<T> cast<T>() => Column(super.cast<T>());

  // ************* count *****************

  /// Counts occurrences of [element].
  int count(E object) => where((element) => element == object).length;

  /// Counts column-elements equaling any element contained by [pool].
  int countElementOccurrencesOf(Set<E> pool) =>
      where((element) => pool.contains(element)).length;

  // ************* null freeing *************

  /// Returns [Column] without nulls. If [replaceWith] is set to null null-records
  /// are removed from the column, whereas they will replaced by its value otherwise.
  Column<E> nullFree({E? replaceWith = null}) =>
      Column<E>(nullFreeIterable(replaceWith: replaceWith).toList());

  /// Iterable-returning counterpart of [nullFree].
  /// Consult [nullFree] for further documentation.
  Iterable<E> nullFreeIterable({E? replaceWith = null}) => replaceWith == null
      ? where((element) => element != null)
      : map((e) => e ?? replaceWith);

  // ****************** transformation ******************

  /// Returns List<num> containing the cumulative sum of the column.
  /// [treatNullsAsZeros] being set to true will lead to the the result being of
  /// the same length as the original column. Otherwise, null records won't be
  /// accounted for.
  ///
  /// Note: requires column records type to be a subtype of <num?>
  List<num> cumulativeSum({bool treatNullsAsZeros = true}) =>
      _nullFreedNums(treatNullsAsZeros: treatNullsAsZeros).fold(
          [],
          (sums, element) =>
              sums..add(sums.isEmpty ? element : sums.last + element));

  // **************** accumulation ****************

  /// Returns the column's mean. Set [treatNullsAsZeros] for the method
  /// to not account for null records.
  ///
  /// Note: requires column records type to be a subtype of <num?>
  double mean({bool treatNullsAsZeros = true}) =>
      _nullFreedNums(treatNullsAsZeros: treatNullsAsZeros).average;

  /// Returns the column's max. Requires column records type to be a subtype of <num?>
  num max() => _nullFreedNums().max;

  /// Returns the column's min. Requires column records type to be a subtype of <num?>
  num min() => _nullFreedNums().min;

  /// Returns the column's sum. Requires column records type to be a subtype of <num?>
  num sum() => _nullFreedNums().sum;

  Iterable<num> _nullFreedNums({bool treatNullsAsZeros = false}) => cast<num?>()
      .nullFreeIterable(replaceWith: treatNullsAsZeros ? 0 : null)
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

  /// Get a [Mask] by mapping [test] to the column records.
  Mask maskFrom(bool Function(E) test) => map(test).toList().cast<bool>();

  // ****************** numerical column masks *********************

  /// Requires the column records type to be a subtype of num (i.e. non-null!)
  Mask operator <(num reference) =>
      cast<num>().map((element) => element < reference).toList().cast<bool>();

  /// Requires the column records type to be a subtype of num (i.e. non-null!)
  Mask operator >(num reference) =>
      cast<num>().map((element) => element > reference).toList().cast<bool>();

  /// Requires the column records type to be a subtype of num (i.e. non-null!)
  Mask operator <=(num reference) =>
      cast<num>().map((element) => element <= reference).toList().cast<bool>();

  /// Requires the column records type to be a subtype of num (i.e. non-null!)
  Mask operator >=(num reference) =>
      cast<num>().map((element) => element >= reference).toList().cast<bool>();
}

typedef Mask = List<bool>;

/// Operators for the conjunction of masks.
extension MaskExtensions on Mask {
  Mask operator &(Mask other) =>
      IterableZip([this, other]).map((e) => e.first && e.last).toList();

  Mask operator |(Mask other) =>
      IterableZip([this, other]).map((e) => e.first || e.last).toList();

  Mask operator ^(Mask other) =>
      IterableZip([this, other]).map((e) => e.first ^ e.last).toList();
}
