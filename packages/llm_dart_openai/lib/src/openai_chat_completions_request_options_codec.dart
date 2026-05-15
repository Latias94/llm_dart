import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_model_capabilities.dart';
import 'openai_options.dart';
import 'openai_request_encoding_util.dart';
import 'resolved_openai_options.dart';

final class OpenAIChatCompletionsRequestOptionsCodec {
  final String providerNamespace;

  const OpenAIChatCompletionsRequestOptionsCodec({
    this.providerNamespace = 'openai',
  });

  void validateUnsupportedProviderOptions(
    ResolvedOpenAIGenerateTextOptions providerOptions,
  ) {
    if (providerOptions.common.previousResponseId != null) {
      throw UnsupportedError(
        'OpenAI-family chat-completions requests do not support previousResponseId. Use the Responses API mainline instead.',
      );
    }

    if (providerOptions.common.builtInTools case final builtInTools?
        when builtInTools.isNotEmpty) {
      throw UnsupportedError(
        'OpenAI-family chat-completions requests do not support OpenAI built-in tools. Use the Responses API mainline instead.',
      );
    }

    if (providerOptions.common.instructions != null) {
      throw UnsupportedError(
        'OpenAI-family chat-completions requests do not support instructions. Use the Responses API mainline instead.',
      );
    }

    if (providerOptions.common.maxToolCalls != null) {
      throw UnsupportedError(
        'OpenAI-family chat-completions requests do not support maxToolCalls. Use the Responses API mainline instead.',
      );
    }

    if (providerOptions.common.metadata != null) {
      throw UnsupportedError(
        'OpenAI-family chat-completions requests do not support metadata. Use the Responses API mainline instead.',
      );
    }

    if (providerOptions.common.truncation != null) {
      throw UnsupportedError(
        'OpenAI-family chat-completions requests do not support truncation. Use the Responses API mainline instead.',
      );
    }

    if (providerOptions.common.include case final include?
        when include.isNotEmpty) {
      throw UnsupportedError(
        'OpenAI-family chat-completions requests do not support include. Use the Responses API mainline instead.',
      );
    }

    if (providerOptions.common.promptCacheKey != null) {
      throw UnsupportedError(
        'OpenAI-family chat-completions requests do not support promptCacheKey in the current family-safe mainline. Use the Responses API mainline instead.',
      );
    }

    if (providerOptions.common.promptCacheRetention != null) {
      throw UnsupportedError(
        'OpenAI-family chat-completions requests do not support promptCacheRetention in the current family-safe mainline. Use the Responses API mainline instead.',
      );
    }

    if (providerOptions.common.safetyIdentifier != null) {
      throw UnsupportedError(
        'OpenAI-family chat-completions requests do not support safetyIdentifier in the current family-safe mainline. Use the Responses API mainline instead.',
      );
    }
  }

  OpenAISystemMessageMode resolveSystemMessageMode(
    String modelId,
    OpenAIGenerateTextOptions options,
  ) {
    if (options.systemMessageMode case final mode?) {
      return mode;
    }

    final capabilities = getOpenAIModelCapabilities(modelId);
    final isReasoningModel =
        options.forceReasoning ?? capabilities.isReasoningModel;

    return isReasoningModel
        ? OpenAISystemMessageMode.developer
        : capabilities.systemMessageMode;
  }

  void applyCompatibilityRules({
    required String modelId,
    required OpenAIGenerateTextOptions commonOptions,
    required Map<String, Object?> body,
    required List<ModelWarning> warnings,
  }) {
    _applyOpenAICompatibilityRules(
      modelId: modelId,
      providerOptions: commonOptions,
      body: body,
      warnings: warnings,
    );
    _applyDeepSeekCompatibilityRules(
      modelId: modelId,
      body: body,
      warnings: warnings,
    );
  }

  int encodeChatTopLogProbs(OpenAILogProbs logprobs) {
    return logprobs.topLogProbs ?? 0;
  }

  void _applyOpenAICompatibilityRules({
    required String modelId,
    required OpenAIGenerateTextOptions providerOptions,
    required Map<String, Object?> body,
    required List<ModelWarning> warnings,
  }) {
    if (providerNamespace != 'openai') {
      return;
    }

    final isReasoningModel = _usesOpenAIReasoningCompatibility(
      modelId,
      providerOptions,
    );
    final reasoningEffort = providerOptions.reasoningEffort;
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

  void _applyDeepSeekCompatibilityRules({
    required String modelId,
    required Map<String, Object?> body,
    required List<ModelWarning> warnings,
  }) {
    if (providerNamespace != 'deepseek' || !modelId.contains('reasoner')) {
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
    if (providerNamespace != 'openai') {
      return false;
    }

    return options.forceReasoning ??
        getOpenAIModelCapabilities(modelId).isReasoningModel;
  }
}
