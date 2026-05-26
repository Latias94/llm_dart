import 'package:llm_dart_provider/llm_dart_provider.dart';

import '../language/openai_generate_text_options.dart';
import 'openai_provider_options_namespaces.dart';

final class DeepSeekGenerateTextOptions
    implements ProviderInvocationOptionsBagProjection {
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

  @override
  ProviderOptionsBag toProviderOptionsBag() {
    return ProviderOptionsBag.mergeNullable(
          common.toProviderOptionsBag(),
          ProviderOptionsBag.forProvider(deepSeekProviderOptionsNamespace, {
            'logprobs': logprobs,
            'top_logprobs': topLogprobs,
            'frequency_penalty': frequencyPenalty,
            'presence_penalty': presencePenalty,
            'response_format': responseFormat,
          }),
        ) ??
        ProviderOptionsBag.empty;
  }
}
