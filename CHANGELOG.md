# 0.0.1

Baseline version. Duh.

# 0.0.2

Comply with data file format conventions.

# 0.0.3

Add `toCsv` method. Improve method documentation. Remove the rather pointless `structureInfo` method.

# 0.1.0

- Add `shape` property, `columnIterable`, `withColumns`, `rowsAt`, `rowsWhere`
- Incorporate `Column` class being returned upon accessing a `DataFrame` column, alongside methods for
  - transformation: `cumulativeSum`
  - accumulation: `mean`, `max`, `min`, `sum`
  - counting: `count`, `countElementOccurrencesOf`
  - null-ridding: `nullFree`, `nullFreeIterable`
  - mask conversion: `equals`, `unequals`, `isIn`, `isNotIn`, `maskFrom`; operators: `<`, `>`, `<=`, `>=`
- Enable conditional rows selection based on columns, e.g. `final filteredDf = df.rowsWhere((df('a') > 7) & df('b').equals(null))`