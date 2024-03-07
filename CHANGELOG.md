# 0.0.1

Baseline version. Duh.

# 0.0.2

Comply with data file format conventions.

# 0.0.3

Add `toCsv` method. Improve method documentation. Remove the rather pointless `structureInfo` method.

# 0.1.0

- Add `shape` property & `columnIterable`, `withColumns`, `multiIndexed`, `masked`
- Incorporate `Column` class being returned upon accessing a `DataFrame` column, alongside methods for
  - transformation: `cumulativeSum`
  - accumulation: `mean`, `max`, `min`, `sum`
  - counting: `count`, `countElementOccurrencesOf`
  - null-ridding: `nullFree`, `nullFreeIterable`
  - mask conversion: `eq`, `neq`, `isIn`, `isNotIn`, `maskFrom`, `gt`, `lt`, `geq`, `leq`
- Enable conditional rows selection based on columns, e.g. 
  ```dart
  final filteredDf = df.masked(df('a').lt(7) & (df('b').eq(null) | df('c').isIn({'super', 'sick', ',', 'brother'})));
  ```
  
# 0.1.1

- Make `shape` an unmodifiable List
- Add `head` method
- Make the `start` and `end` parameters of `slice` and `sliced` keyword parameters
- Add `asView` parameter to non-constructor methods returning a `DataFrame`, to allow for determining whether a view of the current data, or a copy of it should be returned

# 0.1.2

- Update jiffy as well as the dart sdk version range 

# 0.1.3

- Update dart sdk to >=2.13.0 <=3.3.0, csv to 6.0.0

# 0.1.4

- Update dart sdk to >=2.13.0 <=3.3.1