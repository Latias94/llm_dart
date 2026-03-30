import 'package:llm_dart_core/llm_dart_core.dart';

import 'openai_options.dart';

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
