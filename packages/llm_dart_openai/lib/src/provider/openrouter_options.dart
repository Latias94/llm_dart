import 'package:llm_dart_provider/llm_dart_provider.dart';

import '../language/openai_generate_text_options.dart';
import 'openai_model_settings.dart';

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

final class OpenRouterGenerateTextOptions implements ProviderInvocationOptions {
  final OpenAIGenerateTextOptions common;
  final OpenRouterSearchOptions? search;

  const OpenRouterGenerateTextOptions({
    this.common = const OpenAIGenerateTextOptions(),
    this.search,
  });
}
