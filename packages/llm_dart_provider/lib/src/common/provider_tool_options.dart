part of 'provider_options.dart';

/// Provider-owned tool definition customization settings.
///
/// These options configure how a single shared tool definition is encoded by a
/// concrete provider. They are intentionally separate from
/// `ProviderInvocationOptions` so provider-specific tool semantics can travel
/// with the tool definition instead of being indexed indirectly by name.
abstract interface class ProviderToolOptions {
  const ProviderToolOptions();
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
