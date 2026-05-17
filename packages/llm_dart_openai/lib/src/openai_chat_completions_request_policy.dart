import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_model_capabilities.dart';
import 'openai_options.dart';
import 'openai_request_encoding_util.dart';
import 'resolved_openai_options.dart';

abstract class OpenAIChatCompletionsRequestPolicy {
  const OpenAIChatCompletionsRequestPolicy();

  void addProviderRequestFields({
    required String modelId,
    required Map<String, Object?> body,
    required ResolvedOpenAIGenerateTextOptions providerOptions,
    required OpenAIReasoningEffort? effectiveReasoningEffort,
  }) {
    _addCommonLogprobsFields(
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

  void _addCommonLogprobsFields({
    required Map<String, Object?> body,
    required OpenAILogProbs? commonLogprobs,
  }) {
    if (commonLogprobs == null) {
      return;
    }

    body['logprobs'] = true;
    body['top_logprobs'] = _encodeChatTopLogProbs(commonLogprobs);
  }
}

OpenAIChatCompletionsRequestPolicy openAIChatCompletionsRequestPolicyFor(
  String providerNamespace,
) {
  return switch (providerNamespace) {
    'deepseek' => const _DeepSeekChatCompletionsRequestPolicy(),
    'openai' => const _OpenAIChatCompletionsRequestPolicy(),
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
    final isReasoningModel = _usesOpenAIReasoningCompatibility(
      modelId,
      commonOptions,
    );
    final reasoningEffort = commonOptions.reasoningEffort;
    final capabilities = getOpenAIModelCapabilities(modelId);

    if (isReasoningModel) {
      final supportsNonReasoningParameters =
          reasoningEffort == OpenAIReasoningEffort.none &&
              capabilities.supportsNonReasoningParameters;

      if (!supportsNonReasoningParameters) {
        removeOpenAIRequestBodyFieldWithWarning(
          body,
          'temperature',
          warnings,
          warning: const ModelWarning(
            type: ModelWarningType.unsupported,
            field: 'temperature',
            message: 'temperature is not supported for reasoning models',
          ),
        );
        removeOpenAIRequestBodyFieldWithWarning(
          body,
          'top_p',
          warnings,
          warning: const ModelWarning(
            type: ModelWarningType.unsupported,
            field: 'topP',
            message: 'topP is not supported for reasoning models',
          ),
        );
        removeOpenAIRequestBodyFieldWithWarning(
          body,
          'logprobs',
          warnings,
          warning: const ModelWarning(
            type: ModelWarningType.unsupported,
            field: 'logprobs',
            message: 'logprobs is not supported for reasoning models',
          ),
        );
        removeOpenAIRequestBodyFieldWithWarning(
          body,
          'top_logprobs',
          warnings,
          warning: const ModelWarning(
            type: ModelWarningType.unsupported,
            field: 'topLogProbs',
            message: 'topLogprobs is not supported for reasoning models',
          ),
        );
      }

      final maxTokens = body.remove('max_tokens');
      if (maxTokens != null && !body.containsKey('max_completion_tokens')) {
        body['max_completion_tokens'] = maxTokens;
      }
    }

    _applyOpenAIServiceTierCompatibility(
      modelId: modelId,
      body: body,
      warnings: warnings,
    );
  }

  void _applyOpenAIServiceTierCompatibility({
    required String modelId,
    required Map<String, Object?> body,
    required List<ModelWarning> warnings,
  }) {
    final serviceTier = body['service_tier'];
    final capabilities = getOpenAIModelCapabilities(modelId);
    if (serviceTier == 'flex' && !capabilities.supportsFlexProcessing) {
      body.remove('service_tier');
      warnings.add(
        const ModelWarning(
          type: ModelWarningType.unsupported,
          field: 'serviceTier',
          message:
              'flex processing is only available for o3, o4-mini, and gpt-5 models',
        ),
      );
    }

    if (serviceTier == 'priority' && !capabilities.supportsPriorityProcessing) {
      body.remove('service_tier');
      warnings.add(
        const ModelWarning(
          type: ModelWarningType.unsupported,
          field: 'serviceTier',
          message:
              'priority processing is only available for supported models (gpt-4, gpt-5, gpt-5-mini, o3, o4-mini) and requires Enterprise access. gpt-5-nano is not supported',
        ),
      );
    }
  }

  bool _usesOpenAIReasoningCompatibility(
    String modelId,
    OpenAIGenerateTextOptions options,
  ) {
    return options.forceReasoning ??
        getOpenAIModelCapabilities(modelId).isReasoningModel;
  }
}

final class _DeepSeekChatCompletionsRequestPolicy
    extends OpenAIChatCompletionsRequestPolicy {
  const _DeepSeekChatCompletionsRequestPolicy();

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
      _addCommonLogprobsFields(
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

int _encodeChatTopLogProbs(OpenAILogProbs logprobs) {
  return logprobs.topLogProbs ?? 0;
}
