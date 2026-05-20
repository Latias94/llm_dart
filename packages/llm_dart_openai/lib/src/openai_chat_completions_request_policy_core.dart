import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_generate_text_options.dart';
import 'resolved_openai_options.dart';

abstract class OpenAIChatCompletionsRequestPolicy {
  const OpenAIChatCompletionsRequestPolicy();

  void addProviderRequestFields({
    required String modelId,
    required Map<String, Object?> body,
    required ResolvedOpenAIGenerateTextOptions providerOptions,
    required OpenAIReasoningEffort? effectiveReasoningEffort,
  }) {
    addCommonLogprobsFields(
      body: body,
      commonLogprobs: providerOptions.common.logprobs,
    );
  }

  void addProviderResponseFormat({
    required Map<String, Object?> body,
    required ResolvedOpenAIGenerateTextOptions providerOptions,
  }) {}

  void applyCompatibilityRules({
    required String modelId,
    required OpenAIGenerateTextOptions commonOptions,
    required Map<String, Object?> body,
    required List<ModelWarning> warnings,
  }) {}

  void addCommonLogprobsFields({
    required Map<String, Object?> body,
    required OpenAILogProbs? commonLogprobs,
  }) {
    if (commonLogprobs == null) {
      return;
    }

    body['logprobs'] = true;
    body['top_logprobs'] = commonLogprobs.topLogProbs ?? 0;
  }
}
