import 'json_codec_common.dart';

/// Provider-owned output metadata.
///
/// `ProviderMetadata` is reserved for provider observations, raw response
/// details, streamed replay hints, and provider continuation data that came
/// from a model result. Input-side request customization belongs in typed
/// `ProviderInvocationOptions` passed through `CallOptions.providerOptions`.
final class ProviderMetadata {
  static final RegExp _namespaceKeyPattern = RegExp(
    r'^[a-z0-9]+(?:[._-][a-z0-9]+)*$',
  );

  static const empty = ProviderMetadata();

  final Map<String, Object?> values;

  const ProviderMetadata([this.values = const {}]);

  ProviderMetadata._(this.values);

  bool get isEmpty => values.isEmpty;

  bool get isNotEmpty => values.isNotEmpty;

  Object? operator [](String key) => values[key];

  bool containsNamespace(String namespace) => values[namespace] is Map;

  Map<String, Object?>? namespace(String namespace) {
    final value = values[namespace];
    if (value is! Map) {
      return null;
    }

    return asJsonMap(
      value,
      path: r'$.providerMetadata.' + namespace,
    );
  }

  ProviderMetadata mergedWith(ProviderMetadata? other) {
    return mergeNullable(this, other) ?? empty;
  }

  JsonMap toJsonMap({
    String path = r'$.providerMetadata',
  }) {
    final jsonMap = asJsonMap(
      ensureJsonValue(values, path: path),
      path: path,
    );
    _validateNamespaceMap(jsonMap, path: path);
    return _freezeJsonMap(jsonMap);
  }

  static ProviderMetadata? forNamespace(
    String namespace,
    Map<String, Object?> values, {
    bool omitNullValues = true,
  }) {
    _validateNamespaceKey(namespace, path: r'$.providerMetadata');

    final namespacePath = r'$.providerMetadata.' + namespace;
    final normalized = <String, Object?>{};
    for (final entry in values.entries) {
      if (omitNullValues && entry.value == null) {
        continue;
      }

      normalized[entry.key] = _freezeJsonValue(
        ensureJsonValue(
          entry.value,
          path: '$namespacePath.${entry.key}',
        ),
      );
    }

    if (normalized.isEmpty) {
      return null;
    }

    return ProviderMetadata._(
      Map.unmodifiable({
        namespace: Map.unmodifiable(normalized),
      }),
    );
  }

  static ProviderMetadata? mergeNullable(
    ProviderMetadata? left,
    ProviderMetadata? right,
  ) {
    if (left == null || left.isEmpty) {
      if (right == null || right.isEmpty) {
        return null;
      }

      return ProviderMetadata._(right.toJsonMap());
    }

    if (right == null || right.isEmpty) {
      return ProviderMetadata._(left.toJsonMap());
    }

    final merged = _deepMergeJsonMaps(left.toJsonMap(), right.toJsonMap());
    return ProviderMetadata._(_freezeJsonMap(merged));
  }

  @override
  bool operator ==(Object other) {
    return other is ProviderMetadata && _deepEquals(values, other.values);
  }

  @override
  int get hashCode => _deepHash(values);

  @override
  String toString() => 'ProviderMetadata($values)';

  static void _validateNamespaceMap(
    JsonMap values, {
    required String path,
  }) {
    for (final entry in values.entries) {
      _validateNamespaceKey(entry.key, path: path);
      asJsonMap(entry.value, path: '$path.${entry.key}');
    }
  }

  static void _validateNamespaceKey(
    String namespace, {
    required String path,
  }) {
    if (_namespaceKeyPattern.hasMatch(namespace)) {
      return;
    }

    throw FormatException(
      'Expected provider namespace key at $path, got "$namespace".',
    );
  }
}

JsonMap _deepMergeJsonMaps(
  JsonMap left,
  JsonMap right,
) {
  final merged = <String, Object?>{
    ...left,
  };

  for (final entry in right.entries) {
    final previous = merged[entry.key];
    final next = entry.value;

    if (previous is Map && next is Map) {
      merged[entry.key] = _deepMergeJsonMaps(
        asJsonMap(previous, path: r'$.providerMetadata'),
        asJsonMap(next, path: r'$.providerMetadata'),
      );
      continue;
    }

    merged[entry.key] = next;
  }

  return merged;
}

Object? _freezeJsonValue(Object? value) {
  return switch (value) {
    List() => List<Object?>.unmodifiable(value.map(_freezeJsonValue)),
    Map() => _freezeJsonMap(
        asJsonMap(
          value,
          path: r'$.providerMetadata',
        ),
      ),
    _ => value,
  };
}

JsonMap _freezeJsonMap(JsonMap value) {
  return Map<String, Object?>.unmodifiable(
    value.map((key, nested) {
      return MapEntry(key, _freezeJsonValue(nested));
    }),
  );
}

bool _deepEquals(Object? left, Object? right) {
  if (identical(left, right)) {
    return true;
  }

  if (left is Map && right is Map) {
    if (left.length != right.length) {
      return false;
    }

    for (final entry in left.entries) {
      if (!right.containsKey(entry.key)) {
        return false;
      }

      if (!_deepEquals(entry.value, right[entry.key])) {
        return false;
      }
    }

    return true;
  }

  if (left is List && right is List) {
    if (left.length != right.length) {
      return false;
    }

    for (var index = 0; index < left.length; index += 1) {
      if (!_deepEquals(left[index], right[index])) {
        return false;
      }
    }

    return true;
  }

  return left == right;
}

int _deepHash(Object? value) {
  return switch (value) {
    null => 0,
    Map() => Object.hashAll(
        value.entries
            .map(
              (entry) => (
                key: entry.key.toString(),
                hash: Object.hash(
                  entry.key,
                  _deepHash(entry.value),
                ),
              ),
            )
            .toList()
          ..sort((left, right) => left.key.compareTo(right.key)),
      ),
    List() => Object.hashAll(value.map(_deepHash)),
    _ => value.hashCode,
  };
}
