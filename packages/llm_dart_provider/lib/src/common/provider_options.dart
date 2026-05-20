import 'json_codec_common.dart';
import 'provider_metadata.dart';

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

/// Explicitly carries both typed provider options and a JSON options bag.
///
/// Typed options remain the preferred Dart Interface. The bag is the transport
/// and cross-process seam. Provider Implementations can merge both; generic
/// typed resolvers unwrap [typedOptions] and ignore the bag.
final class ProviderInvocationOptionsBundle
    implements ProviderInvocationOptions {
  final ProviderInvocationOptions? typedOptions;
  final ProviderOptionsBag bag;

  ProviderInvocationOptionsBundle({
    this.typedOptions,
    ProviderOptionsBag? bag,
  }) : bag = bag ?? ProviderOptionsBag.empty;
}

/// Convenience constructor for a typed/bag invocation options bundle.
ProviderInvocationOptions? providerInvocationOptions({
  ProviderInvocationOptions? typedOptions,
  ProviderOptionsBag? bag,
}) {
  final hasTyped = typedOptions != null;
  final hasBag = bag != null && bag.isNotEmpty;

  if (!hasTyped && !hasBag) {
    return null;
  }

  if (!hasTyped) {
    return bag;
  }

  if (!hasBag) {
    return typedOptions;
  }

  return ProviderInvocationOptionsBundle(
    typedOptions: typedOptions,
    bag: bag,
  );
}

/// Returns the JSON provider options bag carried by invocation options.
ProviderOptionsBag? providerOptionsBagFromInvocationOptions(
  ProviderInvocationOptions? options,
) {
  return switch (options) {
    null => null,
    ProviderOptionsBag() => options,
    ProviderInvocationOptionsBundle(:final typedOptions, :final bag) =>
      ProviderOptionsBag.mergeNullable(
        bag.isEmpty ? null : bag,
        typedOptions is ProviderInvocationOptionsBagProjection
            ? typedOptions.toProviderOptionsBag()
            : null,
      ),
    ProviderInvocationOptionsBagProjection() => options.toProviderOptionsBag(),
    _ => null,
  };
}

/// Returns the typed provider options carried by invocation options.
ProviderInvocationOptions? typedProviderOptionsFromInvocationOptions(
  ProviderInvocationOptions? options,
) {
  return switch (options) {
    null => null,
    ProviderOptionsBag() => null,
    ProviderInvocationOptionsBundle(:final typedOptions) => typedOptions,
    _ => options,
  };
}

/// Returns one provider namespace from an invocation options bag.
JsonMap? providerOptionsNamespaceFromInvocationOptions(
  ProviderInvocationOptions? options,
  String provider,
) {
  return providerOptionsBagFromInvocationOptions(options)?.namespace(provider);
}

/// Provider-owned model construction settings.
///
/// These options select or configure a concrete provider model instance. They
/// are not response metadata.
abstract interface class ProviderModelOptions {
  const ProviderModelOptions();
}

/// Provider-owned request customization settings.
///
/// Implementations use these typed options for input-side provider features
/// that do not belong in shared `GenerateTextOptions`. Response observations
/// and replay details belong in `ProviderMetadata` instead.
abstract interface class ProviderInvocationOptions {
  const ProviderInvocationOptions();
}

/// Typed provider options that can project themselves into JSON bag form.
///
/// This keeps typed options as the primary Dart Interface while giving
/// cross-process seams a provider-owned JSON representation when a concrete
/// options object knows how to preserve itself.
abstract interface class ProviderInvocationOptionsBagProjection
    implements ProviderInvocationOptions {
  const ProviderInvocationOptionsBagProjection();

  ProviderOptionsBag toProviderOptionsBag();
}

/// Provider-owned prompt part customization settings.
///
/// These options configure how a single input prompt part is encoded by a
/// concrete provider. Shared replay options are also modeled here so runtime
/// continuations can carry prior output metadata explicitly through typed
/// input options instead of writing it back into prompt-part fields.
abstract interface class ProviderPromptPartOptions {
  const ProviderPromptPartOptions();
}

/// Provider-owned tool definition customization settings.
///
/// These options configure how a single shared tool definition is encoded by a
/// concrete provider. They are intentionally separate from
/// `ProviderInvocationOptions` so provider-specific tool semantics can travel
/// with the tool definition instead of being indexed indirectly by name.
abstract interface class ProviderToolOptions {
  const ProviderToolOptions();
}

/// Provider-agnostic replay data for a provider-facing prompt part.
///
/// This wrapper is used when a model output part is replayed as prompt history.
/// The metadata still represents provider observations from an earlier output,
/// but the continuation prompt carries it through an explicit input option
/// instead of treating it as freshly-authored request metadata.
final class ProviderReplayPromptPartOptions
    implements ProviderPromptPartOptions {
  final ProviderMetadata metadata;

  const ProviderReplayPromptPartOptions(this.metadata);

  static ProviderReplayPromptPartOptions? fromMetadata(
    ProviderMetadata? metadata,
  ) {
    if (metadata == null || metadata.isEmpty) {
      return null;
    }

    return ProviderReplayPromptPartOptions(metadata);
  }
}

/// JSON codec for provider-agnostic replay prompt options.
final class ProviderReplayPromptPartOptionsJsonCodec
    implements
        ProviderPromptPartOptionsJsonCodec<ProviderReplayPromptPartOptions> {
  static const typeId = 'provider.replayPromptPartOptions';

  const ProviderReplayPromptPartOptionsJsonCodec();

  @override
  String get type => typeId;

  @override
  bool canEncode(ProviderPromptPartOptions options) =>
      options is ProviderReplayPromptPartOptions;

  @override
  JsonMap encode(ProviderPromptPartOptions options) {
    final typed = options as ProviderReplayPromptPartOptions;
    return {
      'metadata': typed.metadata.toJsonMap(path: r'$.data.metadata'),
    };
  }

  @override
  ProviderReplayPromptPartOptions decode(JsonMap json) {
    return ProviderReplayPromptPartOptions(
      ProviderMetadata(
        asJsonMap(json['metadata'], path: r'$.data.metadata'),
      ),
    );
  }
}

const providerReplayPromptPartOptionsJsonCodec =
    ProviderReplayPromptPartOptionsJsonCodec();

/// Extracts replay metadata from shared prompt part options.
ProviderMetadata? providerReplayMetadataFromOptions(
  ProviderPromptPartOptions? options,
) {
  if (options is ProviderReplayPromptPartOptions) {
    return options.metadata;
  }

  return null;
}

/// JSON codec for provider-owned prompt part options.
///
/// Core serialization cannot import concrete provider packages, so providers
/// register these codecs when they need durable prompt JSON that preserves
/// typed part options.
abstract interface class ProviderPromptPartOptionsJsonCodec<
    T extends ProviderPromptPartOptions> {
  const ProviderPromptPartOptionsJsonCodec();

  /// Stable discriminator used in prompt JSON.
  String get type;

  /// Whether this codec can encode the runtime options object.
  bool canEncode(ProviderPromptPartOptions options);

  /// Encodes provider-owned prompt part options as JSON.
  JsonMap encode(ProviderPromptPartOptions options);

  /// Decodes provider-owned prompt part options from JSON.
  T decode(JsonMap json);
}

/// JSON codec for provider-owned tool options.
///
/// Core serialization cannot import concrete provider packages, so providers
/// register these codecs when transport payloads need to preserve typed tool
/// options.
abstract interface class ProviderToolOptionsJsonCodec<
    T extends ProviderToolOptions> {
  const ProviderToolOptionsJsonCodec();

  /// Stable discriminator used in transport JSON.
  String get type;

  /// Whether this codec can encode the runtime options object.
  bool canEncode(ProviderToolOptions options);

  /// Encodes provider-owned tool options as JSON.
  JsonMap encode(ProviderToolOptions options);

  /// Decodes provider-owned tool options from JSON.
  T decode(JsonMap json);
}

/// Resolves provider-owned model settings to the expected concrete type.
T resolveProviderModelOptions<T extends ProviderModelOptions>(
  ProviderModelOptions options, {
  required String parameterName,
  required String expectedTypeName,
  String? usageContext,
}) {
  if (options is T) {
    return options;
  }

  throw ArgumentError.value(
    options,
    parameterName,
    _expectedProviderOptionMessage(
      expectedTypeName: expectedTypeName,
      usageContext: usageContext,
    ),
  );
}

/// Resolves nullable provider-owned invocation options to the expected type.
T? resolveProviderInvocationOptions<T extends ProviderInvocationOptions>(
  ProviderInvocationOptions? options, {
  required String parameterName,
  required String expectedTypeName,
  String? usageContext,
}) {
  final typedOptions = typedProviderOptionsFromInvocationOptions(options);
  if (typedOptions == null) {
    return null;
  }

  if (typedOptions is T) {
    return typedOptions;
  }

  throw ArgumentError.value(
    typedOptions,
    parameterName,
    _expectedProviderOptionMessage(
      expectedTypeName: expectedTypeName,
      usageContext: usageContext,
    ),
  );
}

/// Resolves nullable provider-owned prompt part options to the expected type.
T? resolveProviderPromptPartOptions<T extends ProviderPromptPartOptions>(
  ProviderPromptPartOptions? options, {
  required String parameterName,
  required String expectedTypeName,
  String? usageContext,
}) {
  if (options == null) {
    return null;
  }

  if (options is T) {
    return options;
  }

  if (options is ProviderReplayPromptPartOptions) {
    return null;
  }

  throw ArgumentError.value(
    options,
    parameterName,
    _expectedProviderOptionMessage(
      expectedTypeName: expectedTypeName,
      usageContext: usageContext,
    ),
  );
}

/// Resolves nullable provider-owned tool options to the expected type.
T? resolveProviderToolOptions<T extends ProviderToolOptions>(
  ProviderToolOptions? options, {
  required String parameterName,
  required String expectedTypeName,
  String? usageContext,
}) {
  if (options == null) {
    return null;
  }

  if (options is T) {
    return options;
  }

  throw ArgumentError.value(
    options,
    parameterName,
    _expectedProviderOptionMessage(
      expectedTypeName: expectedTypeName,
      usageContext: usageContext,
    ),
  );
}

String _expectedProviderOptionMessage({
  required String expectedTypeName,
  required String? usageContext,
}) {
  if (usageContext == null || usageContext.isEmpty) {
    return 'Expected $expectedTypeName.';
  }

  return 'Expected $expectedTypeName for $usageContext.';
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
