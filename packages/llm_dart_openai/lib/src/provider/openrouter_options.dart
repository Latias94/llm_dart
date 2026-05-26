import 'package:llm_dart_provider/llm_dart_provider.dart';

import '../language/openai_generate_text_options.dart';
import 'openai_model_settings.dart';
import 'openai_provider_options_namespaces.dart';

enum OpenRouterSearchMode {
  onlineModel,
}

final class OpenRouterSearchOptions {
  final OpenRouterSearchMode mode;

  const OpenRouterSearchOptions.onlineModel()
      : mode = OpenRouterSearchMode.onlineModel;
}

final class OpenRouterChatModelSettings implements ProviderModelOptions {
  final OpenAIChatModelSettings common;
  final OpenRouterSearchOptions? search;

  const OpenRouterChatModelSettings({
    this.common = const OpenAIChatModelSettings(),
    this.search,
  });
}

final class OpenRouterGenerateTextOptions
    implements ProviderInvocationOptionsBagProjection {
  final OpenAIGenerateTextOptions common;
  final OpenRouterSearchOptions? search;

  const OpenRouterGenerateTextOptions({
    this.common = const OpenAIGenerateTextOptions(),
    this.search,
  });

  @override
  ProviderOptionsBag toProviderOptionsBag() {
    return ProviderOptionsBag.mergeNullable(
          common.toProviderOptionsBag(),
          ProviderOptionsBag.forProvider(openRouterProviderOptionsNamespace, {
            'search': switch (search?.mode) {
              OpenRouterSearchMode.onlineModel => {'mode': 'online_model'},
              null => null,
            },
          }),
        ) ??
        ProviderOptionsBag.empty;
  }
}
