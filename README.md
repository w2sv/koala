# koala

[![Build](https://github.com/w2sv/koala/actions/workflows/build.yaml/badge.svg)](https://github.com/w2sv/koala/actions/workflows/build.yaml)
[![codecov](https://codecov.io/gh/w2sv/koala/branch/feature/elaboration/graph/badge.svg?token=LI73RYG6T0)](https://codecov.io/gh/w2sv/koala)
[![GitHub](https://img.shields.io/github/license/w2sv/koala?style=plastic)](https://github.com/w2sv/koala/blob/master/LICENSE)

A poor man's version of a pandas DataFrame.\
Read, collect, access & manipulate related data.

## Install

```shell
flutter pub add koala
# or
dart pub add koala
```

## Examples

Create a DataFrame from a csv file, preexisting column names and data, map 
representations of the data or create an empty DataFrame and provide it with its 
properties later on  

```dart
final fromCsv = Dataframe.fromCsv(
    path: 'path/to/file.csv', 
    eolToken: '\n', 
    maxRows: 40,
    skipColumns: ['date'],
    convertDates: true,
    datePattern: 'dd-MM-yyyy'
);

final fromNamesAndData = DataFrame.fromNamesAndData(
    ['a', 'b'], 
    [
      [1, 2],
      [3, 4],
      [69, 420]
    ]
);
```

The `DataFrame` class inherits from the list which contains its data matrix, so rows
may be accessed through normal indexing.
Columns on the other hand can be accessed by calling the instance with a contained column name.

```dart
// get a row
final secondRow = df[1];

// get a column
final bColumn = df('b');
final typedBColumn = df<double?>('b');
final slicedBColumn = df('b', start: 1, end: 5);
final filteredBColumn = df('b', includeRecord: (el) => el > 7);

// grab a singular record
final record = df<int>.record(3, 'b');
```

Manipulate rows & column

```dart
// add and remove rows through the built-in list methods 
df.add([2, 5]);
df.removeAt(4);
df.removeLast();

// manipulate columns
df.addColumn('newColumn', [4, 8, 2]);
df.removeColumn('newColumn');
df.transformColumn('a', (record) => record * 2);
```

Copy or slice the `DataFrame`

```dart
final copy = df.copy();
final sliced = df.sliced(30, 60);   
df.slice(10, 15);  // in-place counterpart
```

Sort the `DataFrame` in-place or get a sorted copy of it

```dart
final sorted = df.sortedBy('a', ascending: true, nullFirst: false);
sorted.sortBy('b', ascending: false, compareRecords: (a, b) => Comparable.compare(a.toString().length, b.toString().length));
```

Obtain a readable representation of the `DataFrame` by simply passing it to the print function
```dart
DataFrame df = DataFrame.fromRowMaps([
  {'col1': 1, 'col2': 2},
  {'col1': 1, 'col2': 1},
  {'col1': null, 'col2': 8},
]);
print(df);
```
leads to the output:

```text
    col1 col2
0 | 1    2   
1 | 1    1   
2 | null 8   
```

...and so on and so forth.

## Contribution

I intend to actively maintain this repo, so feel free to create PRs, as there
still is a hell of a lot of functionality one may add to the `DataFrame`.

## Acknowledgements

This repository started off as a fork from the as of now unmaintained and generally lackluster [df](https://github.com/synw/df),
ultimately however, I wound up rewriting basically everything. Still, shout out boyz. 

## Author

C'est moi, w2sv
