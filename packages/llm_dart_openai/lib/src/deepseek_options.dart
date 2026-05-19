import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_generate_text_options.dart';

final class DeepSeekGenerateTextOptions implements ProviderInvocationOptions {
  final OpenAIGenerateTextOptions common;
  final bool? logprobs;
  final int? topLogprobs;
  final double? frequencyPenalty;
  final double? presencePenalty;
  final Map<String, Object?>? responseFormat;

  const DeepSeekGenerateTextOptions({
    this.common = const OpenAIGenerateTextOptions(),
    this.logprobs,
    this.topLogprobs,
    this.frequencyPenalty,
    this.presencePenalty,
    this.responseFormat,
  });
}
