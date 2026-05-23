part of 'provider_options.dart';

/// Provider-owned prompt part customization settings.
///
/// These options configure how a single input prompt part is encoded by a
/// concrete provider. Shared replay options are also modeled here so runtime
/// continuations can carry prior output metadata explicitly through typed
/// input options instead of writing it back into prompt-part fields.
abstract interface class ProviderPromptPartOptions {
  const ProviderPromptPartOptions();
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
