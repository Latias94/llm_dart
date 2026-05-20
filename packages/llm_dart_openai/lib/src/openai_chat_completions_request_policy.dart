import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_chat_completions_deepseek_policy.dart';
import 'openai_chat_completions_openai_compatibility.dart';
import 'openai_chat_completions_request_policy_core.dart';
import 'openai_family_profile.dart';
import 'openai_generate_text_options.dart';
import 'resolved_openai_options.dart';

export 'openai_chat_completions_request_policy_core.dart'
    show OpenAIChatCompletionsRequestPolicy;

OpenAIChatCompletionsRequestPolicy openAIChatCompletionsRequestPolicyFor(
  String providerNamespace,
) {
  return switch (providerNamespace) {
    'deepseek' => const DeepSeekChatCompletionsRequestPolicy(),
    'openai' => const _OpenAIChatCompletionsRequestPolicy(),
    _ => const _CompatibleChatCompletionsRequestPolicy(),
  };
}

OpenAIChatCompletionsRequestPolicy openAIChatCompletionsRequestPolicyForProfile(
  OpenAIFamilyProfile profile,
) {
  return switch (profile) {
    DeepSeekProfile() => const DeepSeekChatCompletionsRequestPolicy(),
    OpenAIProfile() => const _OpenAIChatCompletionsRequestPolicy(),
    _ => const _CompatibleChatCompletionsRequestPolicy(),
  };
}

final class _CompatibleChatCompletionsRequestPolicy
    extends OpenAIChatCompletionsRequestPolicy {
  const _CompatibleChatCompletionsRequestPolicy();
}

final class _OpenAIChatCompletionsRequestPolicy
    extends OpenAIChatCompletionsRequestPolicy {
  const _OpenAIChatCompletionsRequestPolicy();

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
