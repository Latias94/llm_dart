part of 'provider_options.dart';

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
