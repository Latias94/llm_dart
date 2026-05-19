import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'anthropic_cache_options.dart';

final class AnthropicPromptPartOptions implements ProviderPromptPartOptions {
  final AnthropicCacheControl? cacheControl;

  const AnthropicPromptPartOptions({
    this.cacheControl,
  });
}

final class AnthropicPromptPartOptionsJsonCodec
    implements ProviderPromptPartOptionsJsonCodec<AnthropicPromptPartOptions> {
  static const typeId = 'anthropic.promptPartOptions';

  const AnthropicPromptPartOptionsJsonCodec();

  @override
  String get type => typeId;

  @override
  bool canEncode(ProviderPromptPartOptions options) =>
      options is AnthropicPromptPartOptions;

  @override
  JsonMap encode(ProviderPromptPartOptions options) {
    final typed = options as AnthropicPromptPartOptions;
    return {
      if (typed.cacheControl != null)
        'cacheControl': typed.cacheControl!.toJson(),
    };
  }

  @override
  AnthropicPromptPartOptions decode(JsonMap json) {
    final cacheControlJson = json['cacheControl'];
    if (cacheControlJson == null) {
      return const AnthropicPromptPartOptions();
    }

    final cacheControl = asJsonMap(
      cacheControlJson,
      path: r'$.data.cacheControl',
    );
    return AnthropicPromptPartOptions(
      cacheControl: AnthropicCacheControl(
        type: asJsonString(cacheControl['type'],
            path: r'$.data.cacheControl.type'),
        ttl: asNullableJsonString(
          cacheControl['ttl'],
          path: r'$.data.cacheControl.ttl',
        ),
      ),
    );
  }
}

const anthropicPromptPartOptionsJsonCodec =
    AnthropicPromptPartOptionsJsonCodec();
