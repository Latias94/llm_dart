import 'openai_options.dart';
import 'xai_options.dart';

final class ResolvedOpenAIGenerateTextOptions {
  final OpenAIGenerateTextOptions common;
  final XAILiveSearchOptions? xaiSearch;

  const ResolvedOpenAIGenerateTextOptions({
    this.common = const OpenAIGenerateTextOptions(),
    this.xaiSearch,
  });
}
