import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_chat_completions_openai_compatibility.dart';
import 'openai_chat_completions_request_policy_core.dart';
import '../language/openai_generate_text_options.dart';
import '../provider/resolved_openai_options.dart';

export 'openai_chat_completions_request_policy_core.dart'
    show OpenAIChatCompletionsRequestPolicy;

final class CompatibleChatCompletionsRequestPolicy
    extends OpenAIChatCompletionsRequestPolicy {
  const CompatibleChatCompletionsRequestPolicy();
}

final class OpenAIChatCompletionsOpenAIRequestPolicy
    extends OpenAIChatCompletionsRequestPolicy {
  const OpenAIChatCompletionsOpenAIRequestPolicy();

  @override
  void addProviderRequestFields({
    required String modelId,
    required Map<String, Object?> body,
    required ResolvedOpenAIGenerateTextOptions providerOptions,
    required OpenAIReasoningEffort? effectiveReasoningEffort,
  }) {
    super.addProviderRequestFields(
      modelId: modelId,
      body: body,
      providerOptions: providerOptions,
      effectiveReasoningEffort: effectiveReasoningEffort,
    );

    if (effectiveReasoningEffort != null) {
      body['reasoning_effort'] = effectiveReasoningEffort.value;
    }
    if (providerOptions.common.maxCompletionTokens != null) {
      body['max_completion_tokens'] =
          providerOptions.common.maxCompletionTokens;
    }
  }

  @override
  void applyCompatibilityRules({
    required String modelId,
    required OpenAIGenerateTextOptions commonOptions,
    required Map<String, Object?> body,
    required List<ModelWarning> warnings,
  }) {
    applyOpenAIChatCompletionsCompatibility(
      modelId: modelId,
      commonOptions: commonOptions,
      body: body,
      warnings: warnings,
    );
  }
}
