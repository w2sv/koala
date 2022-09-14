import 'dart:io';

import 'package:koala/koala.dart';
import 'package:test/test.dart';

String _csvPath(String name) => 'test/data/$name';

extension RecordsExtensions on Records {
  Set<Type> _types() => map((e) => e.runtimeType).toSet();
}

DataFrame _getDF() => DataFrame.fromRowMaps([
      {'col1': 1, 'col2': 2},
      {'col1': 1, 'col2': 1},
      {'col1': null, 'col2': 8},
    ]);

final _outputDir = Directory('test/output');

String _outputFilePath(String name) => '${_outputDir.path}/$name';

void main() {
  test('fromRowMaps', () async {
    final date = DateTime.now();
    final rows = [
      {'col1': 'a', 'col2': 1, 'col3': 1.0, 'col4': date},
      {'col1': 'b', 'col2': 2, 'col3': 2.0, 'col4': date},
      {'col1': 'c', 'col2': 3, 'col3': null, 'col4': null},
    ];
    DataFrame df = DataFrame.fromRowMaps(rows);
    expect(df.length, 3);
    expect(df.columnNames, <String>['col1', 'col2', 'col3', 'col4']);
    expect(df.rowMaps(), rows);
    expect(df, <Object>[
      ['a', 1, 1.0, date],
      ['b', 2, 2.0, date],
      ['c', 3, null, null],
    ]);
    expect(df<String>('col1'), ['a', 'b', 'c']);
    expect(df<String>('col1', end: 1), ['a']);
    expect(df<String>('col1', start: 1, end: 1), <String>[]);
    expect(df<String>('col1', start: 1, end: 2), ['b']);
    expect(df.columnNames, ['col1', 'col2', 'col3', 'col4']);
  });

  group('fromCsv', () {
    test('basic parsing', () async {
      DataFrame df = await DataFrame.fromCsv(
          path: _csvPath('with_date.csv'), convertDates: false, eolToken: '\n');
      expect(df.columnNames, ['symbol', 'date', 'price', 'n']);
      expect(df.length, 2);
      expect(df('price')._types(), {double});
      expect(df('n')._types(), {int});
    });

    test('automatic date conversion', () async {
      DataFrame df = await DataFrame.fromCsv(
          path: _csvPath('iso_date.csv'), eolToken: '\n');
      expect(df('date')._types(), {DateTime});
      expect(df('date').map((el) => el.toString()).toList(),
          ['2020-04-12 12:16:54.220', '2020-04-12 12:16:54.220']);
    });

    test('date conversion with specified format', () async {
      DataFrame df = await DataFrame.fromCsv(
          path: _csvPath('with_date.csv'),
          eolToken: '\n',
          datePattern: 'MMM d yyyy');

      expect(df('date')._types(), {DateTime});
    });

    test('newline at the end of file', () async {
      DataFrame df = await DataFrame.fromCsv(
          path: _csvPath('terminating_newline.csv'), eolToken: '\n');
      expect(df.length, 1);
    });

    test('max rows', () async {
      DataFrame df = await DataFrame.fromCsv(
          path: _csvPath('stocks.csv'), eolToken: '\n', maxRows: 20);
      expect(df.length, 20);
    });

    test('no header', () async {
      DataFrame df = await DataFrame.fromCsv(
          path: _csvPath('no_header.csv'),
          eolToken: '\n',
          containsHeader: false,
          columnNames: ['symbol', 'date', 'price', 'n']);
      expect(df.length, 2);
      expect(df.columnNames, ['symbol', 'date', 'price', 'n']);
    });

    test('skip columns', () async {
      DataFrame df = await DataFrame.fromCsv(
          path: _csvPath('with_date.csv'),
          eolToken: '\n',
          skipColumns: ['price']);
      expect(df.length, 2);
      expect(df.columnNames, ['symbol', 'date', 'n']);
      expect(df, [
        ['MSFT', 'Jan 1 2000', 1],
        ['MSFT', 'Feb 1 2000', 2]
      ]);
    });
  });

  test('columns', () {
    final df = _getDF();
    expect(df.columnNames, ['col1', 'col2']);
    expect(df.nColumns, 2);
  });

  test('copying', () {
    final df = _getDF();
    final copy = df.copy()..removeLast();
    expect(df == copy, false);
    expect(df.length == 3 && copy.length == 2, true);
  });

  test('object overrides', () {
    final df = _getDF();
    final df1 = _getDF()..columnNames.add('col3');

    expect(df.hashCode == df1.hashCode, false);
    expect(df == df1, false);

    expect(
        df.toString(),
        '    col1 col2\n'
        '0 | 1    2   \n'
        '1 | 1    1   \n'
        '2 | null 8   ');

    final df_with_longer_elements_than_column_names =
        DataFrame.fromNamesAndData([
      'a',
      'b'
    ], [
      [888, 1],
      [null, 8972]
    ]);
    expect(
        df_with_longer_elements_than_column_names.toString(),
        '    a    b   \n'
        '0 | 888  1   \n'
        '1 | null 8972');
  });

  test('slicing', () async {
    DataFrame df =
        (await DataFrame.fromCsv(path: _csvPath('stocks.csv'), eolToken: '\n'))
          ..slice(0, 30);
    expect(df.length, 30);

    final sliced = df.sliced(5, 25);
    expect(sliced.length, 20);

    // Ensure disentanglement of copied properties
    expect(df.length, 30);
    sliced.removeColumn('symbol');
    expect(df.columnNames, ['symbol', 'date', 'price']);
  });

  test('mutate', () async {
    final rows = <Map<String, Object>>[
      {'col1': 0, 'col2': 4},
      {'col1': 1, 'col2': 2},
    ];
    DataFrame df = DataFrame.fromRowMaps(rows);

    // add and remove row
    df.addRowFromMap(<String, Object>{'col1': 4, 'col2': 2});
    expect(df.length, 3);

    df.removeAt(2);
    expect(df.rowMaps(), rows);

    // add and remove column
    df.addColumn('col3', [5, 3]);
    expect(df.rowMaps(), [
      {'col1': 0, 'col2': 4, 'col3': 5},
      {'col1': 1, 'col2': 2, 'col3': 3}
    ]);

    df.removeColumn('col3');
    expect(df.rowMaps(), rows);

    // transform column
    df.transformColumn('col1', (element) => element + 2);
    expect(df('col1'), [2, 3]);

    // error throwing on .addColumn
    expect(() => df.addColumn('col2', [1, 2]), throwsArgumentError);
    expect(() => df.addColumn('col3', [1, 2, 3]), throwsArgumentError);
  });

  test('columns & record access', () {
    final df = _getDF();

    // column access
    expect(df('col1'), [1, 1, null]);
    expect(df('col1', includeRecord: (element) => element != null), [1, 1]);
    expect(() => df('nonExistent'), throwsArgumentError);

    // typing
    expect(df('col1').runtimeType.toString(), 'Column<dynamic>');
    expect(df<int?>('col1').runtimeType.toString(), 'Column<int?>');

    // columnIterable
    expect(df.columns().toList(), [
      [1, 1, null],
      [2, 1, 8]
    ]);

    // df.rowsWhere((df('col1') > 6) & (df('col2') <= 5));

    // record
    expect(df.record(2, 'col1'), null);
    expect(df.record(2, 'col2'), 8);
  });

  test('map conversions', () {
    final df = _getDF();

    expect(df.columnMap(), {
      'col1': [1, 1, null],
      'col2': [2, 1, 8]
    });
    expect(df.rowMaps(), [
      {'col1': 1, 'col2': 2},
      {'col1': 1, 'col2': 1},
      {'col1': null, 'col2': 8},
    ]);
  });

  test('numerical column extensions', () async {
    final df = _getDF();
    expect(df<int?>('col1').mean(treatNullsAsZeros: false), 1.0);
    expect(df<int?>('col1').mean(treatNullsAsZeros: true), closeTo(2 / 3, 1e-6));
    expect(df<int?>('col1').cumSum(), [1, 2]);
  });

  test('generic column extensions', () async {
    final df = _getDF();
    expect(df('col1').count(null), 1);
    expect(df('col2').countElementOccurrencesOf({1, 2}), 2);

    expect(df('col1').nullFreed(), [1, 1]);
    expect(df('col1').nullFreed(replaceWith: 69), [1, 1, 69]);
  });

  test('sorting', () async {
    final DataFrame df1 = DataFrame.fromRowMaps([
      {'col1': 1, 'col2': 'd'},
      {'col1': 2, 'col2': 'c'},
      {'col1': null, 'col2': null},
      {'col1': 3, 'col2': 'b'},
      {'col1': 4, 'col2': 'a'},
    ])
      ..sortBy('col2');

    const col1PostSort = [null, 4, 3, 2, 1];

    expect(df1<String?>('col2'), [null, 'a', 'b', 'c', 'd']);
    expect(df1<int?>('col1'), col1PostSort);

    final df2 = df1.sortedBy('col1', nullsFirst: false);
    expect(df2<int?>('col1'), [1, 2, 3, 4, null]);
    // Ensure df has not been modified
    expect(df1<int?>('col1'), col1PostSort);

    final df3 = df1.sortedBy('col1', nullsFirst: true);
    expect(df3<int?>('col1'), [null, 1, 2, 3, 4]);

    final df4 = df1.sortedBy('col2', ascending: false, nullsFirst: true);
    expect(df4('col2'), ['d', 'c', 'b', 'a', null]);

    final df5 = df1.sortedBy('col2', ascending: false, nullsFirst: false);
    expect(df5('col2'), [null, 'd', 'c', 'b', 'a']);

    final df6 = df1.sortedBy('col1', compareRecords: (a, b) => 1);
    expect(df6('col1'), [1, 2, 3, 4, null]);

    final df6_1 = df1.sortedBy('col1', compareRecords: (a, b) => -1);
    expect(df6_1('col1'), [null, 4, 3, 2, 1]);
  });

  group('toCsv', () {
    test('default', () async {
      final outputCsvPath = _outputFilePath('out.csv');
      final df = DataFrame.fromNamesAndData([
        'a',
        'b',
        'c'
      ], [
        [12, 'asdf', 33.53],
        [65, 'dsafa', 89]
      ]);
      df.toCsv(outputCsvPath);
      expect(await DataFrame.fromCsv(path: outputCsvPath), df);
    });

    test('with null', () async {
      final outputCsvPath = _outputFilePath('out1.csv');
      final df = DataFrame.fromNamesAndData([
        'a',
        'b',
        'c'
      ], [
        [12, 'asdf', null],
        [null, 'dsafa', 89]
      ]);
      df.toCsv(outputCsvPath, nullRepresentation: '');
      expect(
          await DataFrame.fromCsv(path: outputCsvPath, parseAsNull: {''}), df);
    });

    // test('with double quote including strings', () async {
    //   final outputCsvPath = _outputFilePath('out1.csv');
    //   final df = DataFrame.fromNamesAndData(['a', 'b', 'c'], [[12, "as'df", 33.53], [65, 'dsafa', 89]]);
    //   df.toCsv(outputCsvPath);
    //   expect(await DataFrame.fromCsv(path: outputCsvPath), df);
    // });

    test('with single quote including strings', () async {
      final outputCsvPath = _outputFilePath('out3.csv');
      final df = DataFrame.fromNamesAndData([
        'a',
        'b',
        'c'
      ], [
        [12, "as''df", 33.53],
        [65, "ds'afa", 89]
      ]);
      df.toCsv(outputCsvPath);
      expect(await DataFrame.fromCsv(path: outputCsvPath), df);
    });

    test('without header', () async {
      final outputCsvPath = _outputFilePath('out4.csv');
      final df = DataFrame.fromNamesAndData([
        'a',
        'b',
        'c'
      ], [
        [12, "asdf", 33.53],
        [65, "dsafa", 89]
      ]);
      df.toCsv(outputCsvPath, includeHeader: false);

      final lines = await File(outputCsvPath).readAsLines();
      expect(lines.length, 2);
      expect(lines.first, '12,asdf,33.53');
    });
  });

  tearDownAll(() {
    _outputDir.list().forEach((element) => element.delete());
  });

  test('misc', () {
    final df = DataFrame.empty();
    expect(df.nColumns, 0);
    expect(df.length, 0);

    expect(() => DataFrame.fromNamesAndData(['b'], []), throwsArgumentError);
    expect(
        () => DataFrame.fromNamesAndData([
              'b'
            ], [
              [888, 1]
            ]),
        throwsArgumentError);
  });
}
