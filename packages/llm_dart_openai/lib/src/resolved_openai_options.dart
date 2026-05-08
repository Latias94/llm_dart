import 'deepseek_options.dart';
import 'openai_options.dart';
import 'openrouter_options.dart';
import 'xai_options.dart';

final class ResolvedOpenAIGenerateTextOptions {
  final OpenAIGenerateTextOptions common;
  final XAILiveSearchOptions? xaiSearch;
  final OpenRouterSearchOptions? openRouterSearch;
  final DeepSeekGenerateTextOptions? deepseek;

  const ResolvedOpenAIGenerateTextOptions({
    this.common = const OpenAIGenerateTextOptions(),
    this.xaiSearch,
    this.openRouterSearch,
    this.deepseek,
  });
}
