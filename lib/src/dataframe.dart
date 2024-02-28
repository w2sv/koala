import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:csv/csv.dart';
import 'package:jiffy/jiffy.dart';

import 'column.dart';
import 'utils/element_position_tracking_list.dart';
import 'utils/extensions/iterable.dart';
import 'utils/extensions/list.dart';
import 'utils/list_base.dart';

typedef Record = Object?;
typedef RecordRowMap = Map<String, Record>;

typedef Records = List<Record>;
typedef RecordRow = Records;
typedef RecordCol = Records;

typedef DataMatrix = List<RecordRow>;

/// DataFrame for all sorts of data accumulation, analysis & manipulation and collection tasks.
///
/// Row access is granted through regular indexing, as DataFrame extends the data matrix of shape (rows x columns).
/// Columns may be accessed via dataframe('columnName').
class DataFrame extends ListBase<RecordRow> {
  final ElementPositionTrackingList<String> _trackedColumnNames;

  // ************ constructors ****************

  /// Build a dataframe from specified [columnNames] and [data].
  /// The [data] is expected to be of the shape (rows x columns).
  factory DataFrame.fromNamesAndData(
      List<String> columnNames, DataMatrix data) {
    if (data.isEmpty) {
      throw ArgumentError(
          'Did not receive any data; Use DataFrame.empty() to create an empty DataFrame');
    }
    if (columnNames.length != data.first.length) {
      throw ArgumentError('Number of column names = ${columnNames.length} does '
          'not match number of data column = ${data.first.length}');
    }
    return DataFrame._default(columnNames, data);
  }

  /// Builds a dataframe from a list of [rowMaps], e.g.
  /// \[{'col1': 420, 'col2': 69},
  ///  {'col1': 666, 'col2': 1470}\].
  DataFrame.fromRowMaps(List<RecordRowMap> rowMaps)
      : this._default(rowMaps.first.keys.toList(),
            rowMaps.map((e) => e.values.toList()).toList());

  /// Returns an empty dataframe.
  DataFrame.empty() : this._default([], []);

  DataFrame._default(List<String> columnNames, DataMatrix data)
      : this._trackedColumnNames = ElementPositionTrackingList(columnNames),
        super(data);

  // ***************** from/toCsv *****************

  /// Build a dataframe from csv data.
  ///
  /// Pass either a csv file [path] or a [rowStream], which you may process
  /// beforehand in some way.
  ///
  /// [fieldDelimiter], [textDelimiter] & [eolToken] will be
  /// passed to the employed [CsvToListConverter].
  ///
  /// If [containsHeader] is set to true (default), the first row of the
  /// converted csv data will be used as column names. Otherwise,
  /// the [columnNames] are to be passed.
  ///
  /// Passing [parseAsNull] leads to the specified value being replaced by null.
  ///
  /// Upon [skipColumns] being specified, the corresponding columns will not be
  /// added to the data frame. Likewise, only [maxRows] rows of csv data, excluding
  /// the eventually included header row, will be read in if specified.
  ///
  /// [convertNumeric] leads to double and int values automatically being
  /// respectively converted. [convertDates] leads to attempting a DateFormat conversion
  /// for each column. This conversion may additionally be parametrized with [datePattern].
  /// A datetime looking like '13.08.2022' could be parsed by setting the [datePattern] to
  /// 'dd.MM.yyyy', for instance.
  static Future<DataFrame> fromCsv(
      {String? path,
      Stream<List<int>>? rowStream,
      Codec decoding = utf8,
      String fieldDelimiter = defaultFieldDelimiter,
      String? textDelimiter = defaultTextDelimiter,
      String eolToken = defaultEol,
      bool containsHeader = true,
      List<String>? columnNames,
      List<String>? skipColumns,
      int? maxRows,
      Set<Record> parseAsNull = const {},
      bool convertNumeric = true,
      bool convertDates = true,
      String? datePattern}) async {
    // do argument validity checks
    if (!((path == null) ^ (rowStream == null))) {
      throw ArgumentError('Pass either a file path or a row stream');
    }

    StreamTransformer<List<int>, String> decoder;
    try {
      decoder = decoding.decoder as StreamTransformer<List<int>, String>;
    } on TypeError catch (_, s) {
      throw ArgumentError(
          'Pass codec whose .decoder property is of type StreamTransformer<List<int>, String>: $s');
    }

    if (!containsHeader && columnNames == null) {
      throw ArgumentError(
          'Pass column names if the csv does not contain a header row');
    }

    // extract fields
    if (path != null) {
      rowStream = File(path).openRead();
    }

    var csvRowStream = rowStream!.transform(decoder).transform(
        CsvToListConverter(
            fieldDelimiter: fieldDelimiter,
            textDelimiter: textDelimiter,
            textEndDelimiter: textDelimiter,
            eol: eolToken,
            shouldParseNumbers: convertNumeric,
            allowInvalid: false));

    // take only {maxRows} rows if passed
    if (maxRows != null) {
      csvRowStream = csvRowStream.take(maxRows + (containsHeader ? 1 : 0));
    }

    final fields = await csvRowStream.toList();

    // if no columnNames passed, get them from fields
    if (columnNames == null) {
      columnNames = fields.removeAt(0).cast<String>();
    }

    // instantiate DataFrame
    final df = DataFrame.fromNamesAndData(columnNames, fields);

    // skip columns if required
    if (skipColumns != null) {
      skipColumns.forEach((name) => df.removeColumn(name));
    }

    // convert records present in [parseAsNull] to null if required;
    //
    // NOTE: this should really be done by the CsvToListConverter, however there's no
    // respective parameter to do so. Iterating twice over the entirety of the data
    // introduces a ton of overhead
    if (parseAsNull.isNotEmpty) {
      df.forEachIndexed((i, row) {
        row.forEachIndexed((j, record) {
          if (parseAsNull.contains(record)) {
            df[i][j] = null;
          }
        });
      });
    }

    // attempt to convert dates if required
    if (convertDates) {
      for (final name in df._trackedColumnNames) {
        try {
          df.transformColumn(
              name,
              (element) => element != null
                  ? Jiffy.parse(element, pattern: datePattern).dateTime
                  : null);
        } catch (_) {}
      }
    }

    return df;
  }

  /// Save the instance as csv to [path].
  ///
  /// Set [includeHeader] to false to only include the data in the csv.
  /// Null values will be saved as [nullRepresentation].
  /// [fieldDelimiter], [textDelimiter] & [eolToken] will be forwarded to the invoked [ListToCsvConverter].
  /// The [encoding] specifies the encoding of the saved file.
  Future<void> toCsv(String path,
      {bool includeHeader = true,
      String? nullRepresentation = null,
      String fieldDelimiter = defaultFieldDelimiter,
      String textDelimiter = '',
      String eolToken = defaultEol,
      Encoding encoding = utf8}) {
    DataMatrix fields = this;

    // NOTE: this should be done by the ListToCsvConverter
    if (nullRepresentation != null) {
      fields = fields
          .map((row) =>
              row.map((e) => e ?? nullRepresentation).toFixedLengthList())
          .toFixedLengthList();
    }

    return File(path).writeAsString(
        ListToCsvConverter().convert(
            includeHeader ? <List<Record>>[columnNames] + fields : fields,
            fieldDelimiter: fieldDelimiter,
            textDelimiter: textDelimiter,
            textEndDelimiter: textDelimiter,
            eol: eolToken,
            delimitAllFields: true),
        encoding: encoding);
  }

  // ************** structure ***************

  /// Returns the number of columns currently held by the instance.
  int get nColumns => columnNames.length;

  List<String> get columnNames => _trackedColumnNames.l;

  /// Returns an unmodifiable list of nRows, nColumns.
  List<int> get shape => List.unmodifiable([length, nColumns]);

  /// Accesses column index in O(1).
  int columnIndex(String colName) {
    try {
      return _trackedColumnNames.indexOf(colName);
    } catch (_) {
      throw ArgumentError("Column named '$colName' not present in DataFrame");
    }
  }

  // ************* data access *****************

  /// Enables (typed) column access.
  ///
  /// If [start] and/or [end] are specified, the column will be sliced respectively.
  Column<T> call<T>(String colName, {int start = 0, int? end}) =>
      Column(columnAsIterable<T>(colName, start: start, end: end).toList());

  /// Returns an iterable over the records of a column sliced as per [start]
  /// and [end].
  Iterable<T> columnAsIterable<T>(String colName, {int start = 0, int? end}) =>
      sublist(start, end).map((row) => row[columnIndex(colName)]).cast<T>();

  /// Returns an iterable over all columns.
  Iterable<Column> columns() => _trackedColumnNames.map(call);

  /// Grab a (typed) record sitting at dataframe[rowIndex][colName].
  T record<T>(int rowIndex, String colName) =>
      this[rowIndex][columnIndex(colName)] as T;

  // ************* view/copy yielding methods *****************

  /// Returns a [DataFrame] consisting of the first [nRows] rows or less if the instance
  /// holds less.
  ///
  /// [asView] set to true leads to a view of the current data being returned, otherwise
  /// a copy will be returned.
  DataFrame head({int nRows = 5, bool asView = true}) => _viewOrCopy(
      _trackedColumnNames.l, getRange(0, min(nRows, length)).toList(), asView);

  /// Returns a [DataFrame] comprised of a subset of present columns specified by [columnNames].
  ///
  /// [asView] set to true leads to a view of the current data being returned, otherwise
  /// a copy will be returned.
  DataFrame withColumns(List<String> columnNames, {bool asView = true}) =>
      _viewOrCopy(
          columnNames, columnNames.map((e) => this(e)).transposed(), asView);

  /// Returns a [DataFrame] composed of the rows specified through [indices].
  ///
  /// [asView] set to true leads to a view of the current data being returned, otherwise
  /// a copy will be returned.
  DataFrame multiIndexed(Iterable<int> indices, {bool asView = true}) =>
      _viewOrCopy(
          _trackedColumnNames.l, indices.map((e) => this[e]).toList(), asView);

  /// Returns a [mask]ed [DataFrame].
  ///
  /// [asView] set to true leads to a view of the current data being returned, otherwise
  /// a copy will be returned.
  DataFrame masked(List<bool> mask, {bool asView = true}) =>
      _viewOrCopy(_trackedColumnNames.l, applyMask(mask).toList(), asView);

  /// Returns a [DataFrame] whose rows have been sliced with respect to [start] & [end].
  ///
  /// [asView] set to true leads to a view of the current data being returned, otherwise
  /// a copy will be returned.
  DataFrame sliced({int start = 0, int? end, bool asView = true}) =>
      _viewOrCopy(columnNames, getRange(start, end ?? length).toList(), asView);

  DataFrame _viewOrCopy(
          List<String> columnNames, DataMatrix data, bool asView) =>
      asView
          ? DataFrame._default(columnNames, data)
          : _copied(columnNames, data);

  // **************** manipulation ******************

  /// Add a new column to the end of the dataframe. The [records] have to be of the same length
  /// as the dataframe.
  void addColumn(String name, RecordCol records) {
    if (_trackedColumnNames.contains(name)) {
      throw ArgumentError('$name column does already exist');
    }

    try {
      records.asMap().forEach((index, row) {
        this[index].add(row);
      });
    } on ArgumentError catch (_) {
      throw ArgumentError(
          'Length of column records does not match the one of the data frame');
    }

    _trackedColumnNames.add(name);
  }

  /// Remove a column from the dataframe and return it.
  RecordCol removeColumn(String name) {
    final index = columnIndex(name);
    _trackedColumnNames.removeAt(index);
    return map((element) {
      element.removeAt(index);
    }).toList();
  }

  /// Transform the values corresponding to [name] as per [transformElement] in-place.
  void transformColumn(
      String name, dynamic Function(dynamic element) transformElement) {
    columnAsIterable(name).forEachIndexed((i, element) {
      this[i][columnIndex(name)] = transformElement(element);
    });
  }

  /// Add a new row represented by [rowMap] of the structure {columnName: record}
  /// to the end of the dataframe.
  void addRowFromMap(RecordRowMap rowMap) =>
      add([for (final name in _trackedColumnNames) rowMap[name]]);

  /// Row-slice instance in-place.
  void slice({int start = 0, int? end}) {
    if (start != 0) removeRange(0, start);
    if (end != null) removeRange(end, length);
  }

  // ************ map representations *************

  /// Returns a list of {columnName: value} Map-representations for each row.
  List<RecordRowMap> rowMaps() =>
      [for (final row in this) Map.fromIterables(_trackedColumnNames, row)];

  /// Returns a {columnName: columnData} representation.
  Map<String, RecordCol> columnMap() => Map.fromIterable(
        _trackedColumnNames,
        value: (name) => this(name),
      );

  // ************ copying *************

  /// Returns a copy of the instance.
  DataFrame copy() => _copied(columnNames, this);

  DataFrame _copied(List<String> names, DataMatrix data) =>
      DataFrame._default(names.copy(), data.copy());

  // **************** sorting ****************

  /// Returns a new dataframe sorted by the column [colName].
  ///
  /// By default, rows are ordered by plugging pairs of records into [Comparable.compare]
  /// whilst taking [ascending] and [nullsFirst] into account.
  ///
  /// To customize sorting, pass a custom [compareRecords] function, in which case
  /// [ascending] and [nullsFirst] will be ignored.
  ///
  /// [sortedBy] does not guarantee a stable sort order.
  DataFrame sortedBy(String colName,
          {bool ascending = true,
          bool nullsFirst = true,
          Comparator<Record>? compareRecords}) =>
      _copied(
        _trackedColumnNames,
        _sort(colName,
            inPlace: false,
            ascending: ascending,
            nullsFirst: nullsFirst,
            compareRecords: compareRecords),
      );

  /// In-place counterpart to [sortedBy].
  ///
  /// For parameter documentation consult [sortedBy]
  void sortBy(String colName,
          {bool ascending = true,
          bool nullsFirst = true,
          Comparator<Record>? compareRecords}) =>
      _sort(colName,
          inPlace: true,
          ascending: ascending,
          nullsFirst: nullsFirst,
          compareRecords: compareRecords);

  DataMatrix _sort(String colName,
      {required bool inPlace,
      required bool ascending,
      required bool nullsFirst,
      required Comparator<Record>? compareRecords}) {
    final index = columnIndex(colName);
    return (inPlace ? this : ListListExtensions(this).copy())
      ..sort((a, b) => _compareRecords(
          a[index], b[index], ascending, nullsFirst, compareRecords));
  }

  static int _compareRecords(Record a, Record b, bool ascending,
      bool nullsFirst, Comparator<Record>? compare) {
    // return compare result if function given
    if (compare != null) return compare(a, b);

    // if null amongst records return according to passed nullsFirst and ascending
    if (a == null && b == null) return 0;

    const bool2Coefficient = {true: 1, false: -1};
    if (a == null) return (nullsFirst ? -1 : 1) * bool2Coefficient[ascending]!;
    if (b == null) return (nullsFirst ? 1 : -1) * bool2Coefficient[ascending]!;

    // otherwise compare as Comparables taking ascending into account
    final comparableA = a as Comparable;
    final comparableB = b as Comparable;

    return ascending
        ? Comparable.compare(comparableA, comparableB)
        : Comparable.compare(comparableB, comparableA);
  }

  // ************* Object overrides ******************

  /// Returns hashCode accounting for both the data and [_trackedColumnNames]
  @override
  int get hashCode => l.hashCode + _trackedColumnNames.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DataFrame && hashCode == other.hashCode);

  /// Returns a readable String representation of the instance including its
  /// row indices, column names & data
  @override
  String toString() {
    final indexColumnLength = length.toString().length;
    final indexColumnDelimiter = ' | ';
    final consecutiveElementDelimiter = ' ';

    final List<int> columnWidths = columns()
        .mapIndexed((index, col) =>
            (col + [columnNames[index]]).map((el) => el.toString().length).max)
        .toList();

    return ' '.padLeft(indexColumnLength + indexColumnDelimiter.length) +
        columnNames
            .mapIndexed((i, el) => el.padRight(columnWidths[i]))
            .join(consecutiveElementDelimiter) +
        '\n' +
        IterableZip([
          Iterable.generate(length)
              .map((e) => e.toString().padLeft(indexColumnLength)),
          map((row) => row
              .mapIndexed((index, element) =>
                  element.toString().padRight(columnWidths[index]))
              .join(consecutiveElementDelimiter))
        ]).map((e) => e.join(indexColumnDelimiter)).join('\n');
  }
}
