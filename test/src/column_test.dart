import 'package:koala/koala.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main(){
  final column = Column([1, 3, 7, null, 2, 0, 87, 34, 3, null]);

  test('counting', (){
    expect(column.count(3), 2);
    expect(column.countElementOccurrencesOf({3, 87, 69}), 3);
  });

  test('null freeing', (){
    expect(column.nullFreed(), Column([1, 3, 7, 2, 0, 87, 34, 3]));
    expect(column.nullFreed(replaceWith: 420), Column([1, 3, 7, 420, 2, 0, 87, 34, 3, 420]));
  });

  test('.cumSum', (){
    expect(column.cumSum(treatNullsAsZeros: true), Column([1, 4, 11, 11, 13, 13, 100, 134, 137, 137]));
    expect(column.cumSum(treatNullsAsZeros: false), Column([1, 4, 11, 13, 13, 100, 134, 137]));
  });

  test('accumulation', (){
    expect(column.sum(), 137);
    expect(column.min(), 0);
    expect(column.max(), 87);
    expect(column.mean(treatNullsAsZeros: false), 17.125);
    expect(column.mean(treatNullsAsZeros: true), 13.7);
  });

  test('masks', (){
    expect(column.equals(3), [false, true, false, false, false, false, false, false, true, false]);
    expect(column.unequals(3), [true, false, true, true, true, true, true, true, false, true]);
    expect(column.isIn({2, 7, 87}), [false, false, true, false, true, false, true, false, false, false]);
    expect(column.isNotIn({2, 7, 87}), [true, true, false, true, false, true, false, true, true, true]);
    expect(column.maskFrom((p0) => p0 == null ? true : p0.isEven), [false, false, false, true, true, true, false, true, false, true]);

    final nullFreed = column.nullFreed(replaceWith: 97);
    expect(nullFreed > 20, [false, false, false, true, false, false, true, true, false, true]);
    expect(nullFreed < 20, [true, true, true, false, true, true, false, false, true, false]);
    expect(nullFreed >= 20, [false, false, false, true, false, false, true, true, false, true]);
    expect(nullFreed <= 20, [true, true, true, false, true, true, false, false, true, false]);
  });
  
  test('mask concatenations', (){
    final mask = [true, true, false];
    final referenceMask = [true, false, false];
    expect(mask & referenceMask, [true, false, false]);
    expect(mask | referenceMask, [true, true, false]);
    expect(mask ^ referenceMask, [false, true, false]);
  });
}