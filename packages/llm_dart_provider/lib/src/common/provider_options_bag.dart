part of 'provider_options.dart';

final RegExp _providerNamespaceKeyPattern = RegExp(
  r'^[a-z0-9]+(?:[._-][a-z0-9]+)*$',
);

/// Provider-specific JSON options keyed by provider namespace.
///
/// This mirrors Vercel AI SDK's provider options bag shape while keeping this
/// library's typed option objects as first-class inputs. The outer map is
/// keyed by provider id (`openai`, `anthropic`, `xai`); each namespace value is
/// a JSON object owned by that provider.
final class ProviderOptionsBag implements ProviderInvocationOptions {
  static const empty = ProviderOptionsBag();

  final Map<String, Object?> values;

  const ProviderOptionsBag([this.values = const {}]);

  ProviderOptionsBag._(this.values);

  /// Builds a bag with a single provider namespace.
  static ProviderOptionsBag? forProvider(
    String provider,
    Map<String, Object?> options, {
    bool omitNullValues = true,
  }) {
    _validateProviderNamespaceKey(provider, path: r'$.providerOptions');

    final namespacePath = r'$.providerOptions.' + provider;
    final normalized = <String, Object?>{};
    for (final entry in options.entries) {
      if (omitNullValues && entry.value == null) {
        continue;
      }

      normalized[entry.key] = _freezeProviderJsonValue(
        ensureJsonValue(
          entry.value,
          path: '$namespacePath.${entry.key}',
        ),
      );
    }

    if (normalized.isEmpty) {
      return null;
    }

    return ProviderOptionsBag._(
      Map.unmodifiable({
        provider: Map.unmodifiable(normalized),
      }),
    );
  }

  factory ProviderOptionsBag.fromJsonMap(
    Map<String, Object?> values, {
    String path = r'$.providerOptions',
  }) {
    final normalized = asJsonMap(
      ensureJsonValue(values, path: path),
      path: path,
    );
    _validateProviderOptionsBagMap(normalized, path: path);
    return ProviderOptionsBag._(_freezeProviderJsonMap(normalized));
  }

  bool get isEmpty => values.isEmpty;

  bool get isNotEmpty => values.isNotEmpty;

  Object? operator [](String provider) => values[provider];

  bool containsNamespace(String provider) => values[provider] is Map;

  Map<String, Object?>? namespace(String provider) {
    final value = values[provider];
    if (value is! Map) {
      return null;
    }

    return asJsonMap(
      value,
      path: r'$.providerOptions.' + provider,
    );
  }

  ProviderOptionsBag mergedWith(ProviderOptionsBag? other) {
    return mergeNullable(this, other) ?? empty;
  }

  JsonMap toJsonMap({
    String path = r'$.providerOptions',
  }) {
    final jsonMap = asJsonMap(
      ensureJsonValue(values, path: path),
      path: path,
    );
    _validateProviderOptionsBagMap(jsonMap, path: path);
    return _freezeProviderJsonMap(jsonMap);
  }

  static ProviderOptionsBag? mergeNullable(
    ProviderOptionsBag? left,
    ProviderOptionsBag? right,
  ) {
    if (left == null || left.isEmpty) {
      if (right == null || right.isEmpty) {
        return null;
      }

      return ProviderOptionsBag._(right.toJsonMap());
    }

    if (right == null || right.isEmpty) {
      return ProviderOptionsBag._(left.toJsonMap());
    }

    final merged = _deepMergeProviderJsonMaps(
      left.toJsonMap(),
      right.toJsonMap(),
    );
    return ProviderOptionsBag._(_freezeProviderJsonMap(merged));
  }

  @override
  bool operator ==(Object other) {
    return other is ProviderOptionsBag &&
        _deepProviderJsonEquals(values, other.values);
  }

  @override
  int get hashCode => _deepProviderJsonHash(values);

  @override
  String toString() => 'ProviderOptionsBag($values)';
}

void _validateProviderOptionsBagMap(
  JsonMap values, {
  required String path,
}) {
  for (final entry in values.entries) {
    _validateProviderNamespaceKey(entry.key, path: path);
    asJsonMap(entry.value, path: '$path.${entry.key}');
  }
}

void _validateProviderNamespaceKey(
  String namespace, {
  required String path,
}) {
  if (_providerNamespaceKeyPattern.hasMatch(namespace)) {
    return;
  }

  throw FormatException(
    'Expected provider namespace key at $path, got "$namespace".',
  );
}

JsonMap _deepMergeProviderJsonMaps(
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
      merged[entry.key] = _deepMergeProviderJsonMaps(
        asJsonMap(previous, path: r'$.providerOptions'),
        asJsonMap(next, path: r'$.providerOptions'),
      );
      continue;
    }

    merged[entry.key] = next;
  }

  return merged;
}

Object? _freezeProviderJsonValue(Object? value) {
  return switch (value) {
    List() => List<Object?>.unmodifiable(value.map(_freezeProviderJsonValue)),
    Map() => _freezeProviderJsonMap(
        asJsonMap(
          value,
          path: r'$.providerOptions',
        ),
      ),
    _ => value,
  };
}

JsonMap _freezeProviderJsonMap(JsonMap value) {
  return Map<String, Object?>.unmodifiable(
    value.map((key, nested) {
      return MapEntry(key, _freezeProviderJsonValue(nested));
    }),
  );
}

bool _deepProviderJsonEquals(Object? left, Object? right) {
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

      if (!_deepProviderJsonEquals(entry.value, right[entry.key])) {
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
      if (!_deepProviderJsonEquals(left[index], right[index])) {
        return false;
      }
    }

    return true;
  }

  return left == right;
}

int _deepProviderJsonHash(Object? value) {
  return switch (value) {
    null => 0,
    Map() => Object.hashAll(
        value.entries
            .map(
              (entry) => (
                key: entry.key.toString(),
                hash: Object.hash(
                  entry.key,
                  _deepProviderJsonHash(entry.value),
                ),
              ),
            )
            .toList()
          ..sort((left, right) => left.key.compareTo(right.key)),
      ),
    List() => Object.hashAll(value.map(_deepProviderJsonHash)),
    _ => value.hashCode,
  };
}
