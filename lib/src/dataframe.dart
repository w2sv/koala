import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:csv/csv.dart';
import 'package:jiffy/jiffy.dart';

import 'list_extensions/extended_list_base.dart';
import 'list_extensions/position_tracking_list.dart';
import 'utils/list.dart';

typedef Record = Object?;
typedef RecordRowMap = Map<String, Record>;

typedef Records = List<Record>;
typedef RecordRow = Records;
typedef RecordCol = Records;

/// DataFrame for all sorts of data accumulation, analysis & manipulation and collection tasks.
///
/// Row access is granted through regular indexing, as DataFrame extends the data matrix of shape (rows x columns).
/// Columns may be accessed via dataframe('columnName').
class DataFrame extends ExtendedListBase<RecordRow> {
  final PositionTrackingList<String> _columnNames;

  // ************ constructors ****************

  /// Build a dataframe from specified [columnNames] and [data].
  /// The [data] is expected to be of the shape (rows x columns).
  DataFrame.fromNamesAndData(List<String> columnNames, List<RecordRow> data):
        this._columnNames = PositionTrackingList(columnNames),
        super(data){
    if (data.isEmpty){
      throw ArgumentError('Did not receive any data; Use DataFrame.empty() to create an empty DataFrame');
    }
    if (columnNames.length != data.first.length){
      throw ArgumentError('Number of column names = ${columnNames.length} does '
                          'not match number of data column = ${data.first.length}');
    }
  }

  /// Build a dataframe from a list of [rowMaps], e.g. 
  /// [{'col1': 420, 'col2': 69},
  ///  {'col1': 666, 'col2': 1470}]
  DataFrame.fromRowMaps(List<RecordRowMap> rowMaps):
        this._columnNames = PositionTrackingList(rowMaps.first.keys.toList()),
        super(rowMaps.map((e) => e.values.toList()).toList());
  
  /// Build an empty dataframe
  DataFrame.empty():
      this._columnNames = PositionTrackingList([]),
      super([]);

  /// Build a dataframe from csv data.
  ///
  /// Pass either a csv file [path] or a [rowStream], which you may process 
  /// beforehand in some way.
  /// 
  /// [fieldDelimiter], [textEndDelimiter], [textEndDelimiter] & [eolToken] will be 
  /// passed to the employed [CsvToListConverter].
  /// 
  /// If [containsHeader] is set to true (default), the first row of the 
  /// converted csv data will be used as column names. Otherwise,
  /// the [columnNames] are to be passed.
  /// 
  /// Upon [skipColumns] being specified, the corresponding columns will not be 
  /// added to the data frame. Likewise, only [maxRows] rows of csv data, excluding
  /// the eventually included header row, will be read in if specified.
  /// 
  /// [convertNumeric] leads to double and int values automatically being 
  /// respectively converted. [convertDates] leads to attempting a DateFormat conversion
  /// for each column.
  static Future<DataFrame> fromCsv(
      {
        String? path,
        Stream<List<int>>? rowStream,
        Codec decoding = utf8,
        String fieldDelimiter = defaultFieldDelimiter,
        String? textDelimiter = defaultTextDelimiter,
        String? textEndDelimiter,
        String eolToken = defaultEol,
        bool containsHeader = true,
        List<String>? columnNames,
        List<String>? skipColumns,
        int? maxRows,
        bool convertNumeric = true,
        bool convertDates = true,
        String? datePattern
      }) async {

    // do argument validity checks
    if (!((path == null) ^ (rowStream == null))){
      throw ArgumentError('Pass either a file path or a row stream');
    }

    StreamTransformer<List<int>, String> decoder;
    try{
      decoder = decoding.decoder as StreamTransformer<List<int>, String>;
    } on TypeError catch (_, s){
      throw ArgumentError('Pass codec whose .decoder property is of type StreamTransformer<List<int>, String>: $s');
    }

    if (!containsHeader && columnNames == null){
      throw ArgumentError('Pass column names if the csv does not contain a header row');
    }

    // extract fields
    if (path != null){
      rowStream = File(path).openRead();
    }

    var csvRowStream = rowStream!
        .transform(decoder)
        .transform(
            CsvToListConverter(
              fieldDelimiter: fieldDelimiter,
              textDelimiter: textDelimiter,
              textEndDelimiter: textEndDelimiter,
              eol: eolToken,
              shouldParseNumbers: convertNumeric,
              allowInvalid: false
            )
        );

    // take only {maxRows} rows if passed
    if (maxRows != null){
      csvRowStream = csvRowStream.take(maxRows + (containsHeader ? 1 : 0));
    }
    
    final fields = await csvRowStream.toList();

    // if no columnNames passed, get them from fields
    if (columnNames == null){
      columnNames = fields.removeAt(0).cast<String>();
    }

    // instantiate DataFrame
    final df = DataFrame.fromNamesAndData(columnNames, fields);

    // skip columns and attempt to convert dates if required
    if (skipColumns != null){
      skipColumns.forEach((name) => df.removeColumn(name));
    }

    if (convertDates){
      for (final name in df._columnNames){
        try{
          df.transformColumn(
              name,
              (element) => element != null ? Jiffy(element, datePattern).dateTime : null
          );
        }
        catch (_){}
      }
    }

    return df;
  }

  // ************* object overrides ******************

  /// Returns hashCode accounting for both the [_data] and [_columnNames]
  @override
  int get hashCode =>
      l.hashCode + _columnNames.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (
          other is DataFrame &&
          this.l == other.l &&
          this._columnNames == other._columnNames
      );

  @override
  String toString(){
    final indexColumnLength = length.toString().length;
    final indexColumnDelimiter = ' | ';
    final consecutiveElementDelimiter = ' ';

    final List<int> columnWidths = columnIterable()
        .mapIndexed(
            (index, col) => (col + [columnNames[index]])
                .map((el) => el.toString().length)
                .max
    )
        .toList();

    return ' '.padLeft(indexColumnLength +
        indexColumnDelimiter.length) +
        columnNames
            .mapIndexed((i, el) => el.padRight(columnWidths[i]))
            .join(consecutiveElementDelimiter) +
        '\n' +
        IterableZip(
        [
          Iterable.generate(length).map((e) => e.toString().padLeft(indexColumnLength)),
          map(
                  (row) => row.mapIndexed(
                          (index, element) => element
                              .toString()
                              .padRight(columnWidths[index])
                  )
                      .join(consecutiveElementDelimiter)
          )
        ]
    )
        .map((e) => e.join(indexColumnDelimiter))
        .join('\n');
  }

  // *********** generic operations ****************

  /// Returns a deep copy of the dataframe
  DataFrame copy() => DataFrame._copied(_columnNames, this);

  DataFrame._copied(PositionTrackingList<String> columns, List<RecordRow> data):
        this._columnNames = columns.copy(),
        super(copy2D(data));
  
  /// Returns a new, row-sliced dataframe
  DataFrame sliced(int start, [int? end]) =>
      DataFrame._copied(
          _columnNames,
          sublist(start, end)
      );

  // ************* attribute access *****************

  List<String> get columnNames => _columnNames;

  /// Returns an iterable over the column data
  Iterable<RecordCol> columnIterable() =>
      _columnNames.map((e) => this(e));

  int get nColumns => _columnNames.length;

  int columnIndex(String colName){
    try{
      return _columnNames.indexOf(colName);
    }
    catch (_){
      throw ArgumentError('Column $colName not contained by DataFrame');
    }
  }

  /// Enables (typed) column access.
  /// 
  /// If [start] and/or [end] are specified the column will be sliced, 
  /// after which [includeRecord] may determine which elements are to be included.
  List<T> call<T>(String colName, {int start = 0, int? end, bool Function(T)? includeRecord}){
    Iterable<T> column = sublist(start, end).map((row) => row._record<T>(columnIndex(colName)));
    if (includeRecord != null){
      column = column.where(includeRecord);
    }
    return column.toList();
  }

  /// Returns a list of {columnName: value} representations for each row.
  List<RecordRowMap> rowMaps() =>
      [
        for (final row in this)
          Map.fromIterables(_columnNames, row)
      ];
  
  /// Returns a {columnName: columnData} representation
  Map<String, RecordCol> columnMap() =>
      Map.fromIterable(
        _columnNames,
        value: (name) => this(name),
      );
  
  /// Grab a typed record sitting at dataframe[rowIndex][colName]
  T record<T>(int rowIndex, String colName) =>
    this[rowIndex]._record<T>(columnIndex(colName));

  // **************** mutation ******************
  
  /// Add a new column to the end of the dataframe. The [records] have to be of the same length
  /// as the dataframe.
  void addColumn(String name, RecordCol records){
    if (_columnNames.contains(name)){
      throw ArgumentError('$name column does already exist');
    }

    try{
      records
          .asMap()
          .forEach((index, row) { this[index].add(row); });
    }
    on ArgumentError catch(_){
      throw ArgumentError('Length of column records does not match the one of the data frame');
    }

    _columnNames.add(name);
  }

  /// Remove a column from the dataframe.
  RecordCol removeColumn(String name){
    final index = columnIndex(name);
    _columnNames.removeAt(index);
    return map((element) {
      element.removeAt(index);
    })
        .toList();
  }

  /// Transform the values corresponding to [name] as per [transformElement] in-place.
  void transformColumn(String name, dynamic Function(dynamic element) transformElement){
    this(name).asMap().forEach((i, element) {
        this[i][columnIndex(name)] = transformElement(element);
    });
  }

  /// Add a new row represented by [rowMap] of the structure {columnName: record}
  /// to the end of the dataframe.
  void addRowFromMap(RecordRowMap rowMap) =>
      add([for (final name in _columnNames) rowMap[name]]);

  /// Slice dataframe in-place.
  void slice(int start, [int? end]) {
    if (start != 0) removeRange(0, start);
    if (end != null) removeRange(end, length);
  }

  // ********* info **********

  String structureRepresentation() =>
    '${_columnNames.length} columns; $length rows; column names: ${_columnNames.join(', ')}';

  // **************** sorting ****************

  /// Get a new dataframe sorted by a column.
  ///
  /// By default, rows are ordered by calling [Comparable.compare] on column
  /// values and nulls are handled according to the specified [nullsFirst].
  /// To customize sorting, you can either use your own [Comparable] as column
  /// values or specify a custom compare function.
  /// Sort_ does not guarantee a stable sort order.
  ///
  /// Note that `nullBehavior` and `compare` are mutually exclusive arguments.
  /// Custom compare functions must handle nulls appropriately.
  DataFrame sortedBy(String colName, {bool ascending = true, bool nullsFirst = true, CompareRecords? compareRecords}) =>
      DataFrame._copied(
        _columnNames,
        _sort(
            colName,
            inPlace: false,
            ascending: ascending,
            nullsFirst: nullsFirst,
            compareRecords: compareRecords
        ),
      );

  /// In-place sort this dataframe by a column.
  ///
  /// By default, rows are ordered by calling [Comparable.compare] on column
  /// values and nulls are handled according to the specified [nullsFirst].
  /// To customize sorting, you can either use your own [Comparable] as column
  /// values or specify a custom compare function.
  /// Sort does not guarantee a stable sort order.
  ///
  /// Note that `nullBehavior` and `compare` are mutually exclusive arguments.
  /// Custom compare functions must handle nulls appropriately.
  void sortBy(String colName, {bool ascending = true, bool nullsFirst = true, CompareRecords? compareRecords}) =>
      _sort(
          colName,
          inPlace: true,
          ascending: ascending,
          nullsFirst: nullsFirst,
          compareRecords: compareRecords
      );

  List<RecordRow> _sort(
      String colName,
      {
        required bool inPlace,
        required bool ascending,
        required bool nullsFirst,
        required CompareRecords? compareRecords
      }) => (inPlace ? this : copy2D(this))..sort(
              (a, b) => _compareRecords(
                  a._record(columnIndex(colName)),
                  b._record(columnIndex(colName)),
                  ascending,
                  nullsFirst,
                  compareRecords
              )
      );

  static int _compareRecords(Record a, Record b, bool ascending, bool nullsFirst, CompareRecords? compare) {
    // return compare result if function given
    if (compare != null) return compare(a, b);

    // if null amongst records return according to passed nullsFirst and ascending
    if (a == null && b == null) return 0;

    const bool2Coefficient = {true: 1, false: -1};
    if (a == null) return (nullsFirst ? -1 : 1) * bool2Coefficient[ascending]!;
    if (b == null) return (nullsFirst ? 1 : -1) * bool2Coefficient[ascending]!;

    // otherwise compare as Comparables whilst taking ascending into account
    final comparableA = a as Comparable;
    final comparableB = b as Comparable;

    if (ascending) {
      return Comparable.compare(comparableA, comparableB);
    }
    else {
      return Comparable.compare(comparableB, comparableA);
    }
  }
}

extension RecordColumnExtensions<T> on List<T>{
  /// Count number of occurrences of [element] of the column [colName].
  int count(T object) =>
      where((element) => element == object).length;

  /// Count number of occurrences of values, corresponding to the column [colName],
  /// equaling any element contained by [pool].
  int countElementOccurrencesOf(Set<T> pool) =>
      where((element) => pool.contains(element)).length;

  Iterable<T> withoutNulls({T? nullReplacement = null}) => nullReplacement == null ?
    where((element) => element != null) :
    map((e) => e ?? nullReplacement);
}

extension NumericalRecordColumnExtensions on List<num?>{
  List<double> cumSum() =>
      _nullPurgedDoubles()
          .fold(
            [],
            (sums, element) => sums..add(sums.isEmpty ? element : sums.last + element)
      );

  double mean({bool treatNullsAsZeros = true}){
    final nullPurged = _nullPurgedDoubles(treatNullsAsZeros: treatNullsAsZeros);
    return nullPurged.sum / nullPurged.length;
  }
  
  List<double> _nullPurgedDoubles({bool treatNullsAsZeros = false}) =>
    (withoutNulls(nullReplacement: treatNullsAsZeros ? 0.0 : null)).map((e) => e!.toDouble()).toList();
}

extension on RecordRow{
  T _record<T>(int colIndex) => this[colIndex] as T;
}

/// A function that compares two objects for sorting. It will return -1 if a
/// should be ordered before b, 0 if a and b are equal wrt to ordering, and 1
/// if a should be ordered after b.
typedef CompareRecords = int Function(Record a, Record b);
