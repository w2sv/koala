import 'package:koala/src/utils/iterable.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  test('transposed', () {
    expect(
        [
          [1, 2, 3],
          [2, 3, 4]
        ].transposed(),
        [
          [1, 2],
          [2, 3],
          [3, 4]
        ]);
  });
}
