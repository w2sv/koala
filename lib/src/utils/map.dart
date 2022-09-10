extension MapExtensions<K, V> on Map<K, V>{
  Map<V, K> inverted() =>
      map((key, value) => MapEntry(value, key));
}