final class ProviderMetadata {
  final Map<String, Object?> values;

  const ProviderMetadata([this.values = const {}]);

  bool get isEmpty => values.isEmpty;

  Object? operator [](String key) => values[key];
}
