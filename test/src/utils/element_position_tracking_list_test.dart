import 'package:koala/src/utils/element_position_tracking_list.dart';
import 'package:koala/src/utils/extensions/list.dart';
import 'package:test/test.dart';

void main() {
  test('PositionTrackingList', () {
    final rawColumns = ['a', 'b', 'c'];

    final columns = ElementPositionTrackingList(rawColumns.copy());

    expect(columns, rawColumns);

    expect(columns.indexOf('a'), 0);
    expect(columns.indexOf('b'), 1);
    expect(columns.indexOf('c'), 2);

    columns.add('d');
    expect(columns.indexOf('d'), 3);

    final removed = columns.removeAt(1);
    expect(columns.contains(rawColumns[1]), false);
    expect(removed, rawColumns[1]);
    expect(columns.indexOf('a'), 0);
    expect(columns.indexOf('c'), 1);
    expect(columns.indexOf('d'), 2);

    columns.addAll(['e', 'f']);
    expect(columns, ['a', 'c', 'd', 'e', 'f']);
    expect(columns.indexOf('a'), 0);
    expect(columns.indexOf('e'), 3);
    expect(columns.indexOf('f'), 4);
  });
}
