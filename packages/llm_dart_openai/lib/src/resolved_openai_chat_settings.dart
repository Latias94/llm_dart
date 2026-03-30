import 'openai_options.dart';
import 'openrouter_options.dart';

final class ResolvedOpenAIChatModelSettings {
  final OpenAIChatModelSettings common;
  final OpenRouterSearchOptions? openRouterSearch;

  const ResolvedOpenAIChatModelSettings({
    this.common = const OpenAIChatModelSettings(),
    this.openRouterSearch,
  });
}
