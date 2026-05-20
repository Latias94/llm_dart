import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_chat_completions_request_policy_core.dart';
import '../language/openai_generate_text_options.dart';
import '../common/openai_request_encoding_util.dart';
import '../provider/resolved_openai_options.dart';

final class DeepSeekChatCompletionsRequestPolicy
    extends OpenAIChatCompletionsRequestPolicy {
  const DeepSeekChatCompletionsRequestPolicy();

  @override
  void addProviderRequestFields({
    required String modelId,
    required Map<String, Object?> body,
    required ResolvedOpenAIGenerateTextOptions providerOptions,
    required OpenAIReasoningEffort? effectiveReasoningEffort,
  }) {
    final deepseekOptions = providerOptions.deepseek;
    final deepseekLogprobs = deepseekOptions?.logprobs;
    final deepseekTopLogprobs = deepseekOptions?.topLogprobs;

    if (deepseekLogprobs != null) {
      body['logprobs'] = deepseekLogprobs;
    } else {
      addCommonLogprobsFields(
        body: body,
        commonLogprobs: providerOptions.common.logprobs,
      );
    }

    if (deepseekTopLogprobs != null) {
      body['top_logprobs'] = deepseekTopLogprobs;
    }

    if (deepseekOptions?.frequencyPenalty != null) {
      body['frequency_penalty'] = deepseekOptions!.frequencyPenalty;
    }
    if (deepseekOptions?.presencePenalty != null) {
      body['presence_penalty'] = deepseekOptions!.presencePenalty;
    }
  }

  @override
  void addProviderResponseFormat({
    required Map<String, Object?> body,
    required ResolvedOpenAIGenerateTextOptions providerOptions,
  }) {
    if (providerOptions.deepseek?.responseFormat case final responseFormat?) {
      body['response_format'] = responseFormat;
    }
  }

  @override
  void applyCompatibilityRules({
    required String modelId,
    required OpenAIGenerateTextOptions commonOptions,
    required Map<String, Object?> body,
    required List<ModelWarning> warnings,
  }) {
    if (!modelId.contains('reasoner')) {
      return;
    }

    removeOpenAIRequestBodyFieldWithWarning(
      body,
      'logprobs',
      warnings,
      warning: const ModelWarning(
        type: ModelWarningType.unsupported,
        field: 'logprobs',
        message: 'logprobs is not supported for DeepSeek reasoner models',
      ),
    );
    removeOpenAIRequestBodyFieldWithWarning(
      body,
      'top_logprobs',
      warnings,
      warning: const ModelWarning(
        type: ModelWarningType.unsupported,
        field: 'topLogprobs',
        message: 'topLogprobs is not supported for DeepSeek reasoner models',
      ),
    );
    removeOpenAIRequestBodyFieldWithWarning(
      body,
      'frequency_penalty',
      warnings,
      warning: const ModelWarning(
        type: ModelWarningType.unsupported,
        field: 'frequencyPenalty',
        message: 'frequencyPenalty has no effect on DeepSeek reasoner models',
      ),
    );
    removeOpenAIRequestBodyFieldWithWarning(
      body,
      'presence_penalty',
      warnings,
      warning: const ModelWarning(
        type: ModelWarningType.unsupported,
        field: 'presencePenalty',
        message: 'presencePenalty has no effect on DeepSeek reasoner models',
      ),
    );
  }
}
