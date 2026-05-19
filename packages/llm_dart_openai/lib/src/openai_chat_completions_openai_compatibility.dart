import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_model_capabilities.dart';
import 'openai_options.dart';
import 'openai_request_encoding_util.dart';

void applyOpenAIChatCompletionsCompatibility({
  required String modelId,
  required OpenAIGenerateTextOptions commonOptions,
  required Map<String, Object?> body,
  required List<ModelWarning> warnings,
}) {
  final isReasoningModel = _usesOpenAIChatCompletionsReasoningCompatibility(
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

  _applyOpenAIChatCompletionsServiceTierCompatibility(
    modelId: modelId,
    body: body,
    warnings: warnings,
  );
}

void _applyOpenAIChatCompletionsServiceTierCompatibility({
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

bool _usesOpenAIChatCompletionsReasoningCompatibility(
  String modelId,
  OpenAIGenerateTextOptions options,
) {
  return options.forceReasoning ??
      getOpenAIModelCapabilities(modelId).isReasoningModel;
}
