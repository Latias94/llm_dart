import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_model_capabilities.dart';
import 'openai_options.dart';
import 'openai_request_encoding_util.dart';

void warnUnsupportedOpenAIResponsesSharedOptions(
  GenerateTextOptions options, {
  required List<ModelWarning> warnings,
}) {
  if (options.frequencyPenalty != null) {
    warnings.add(
      const ModelWarning(
        type: ModelWarningType.unsupported,
        field: 'options.frequencyPenalty',
        message:
            'OpenAI Responses does not support shared frequencyPenalty; use Chat Completions-compatible models when this knob is required.',
      ),
    );
  }

  if (options.presencePenalty != null) {
    warnings.add(
      const ModelWarning(
        type: ModelWarningType.unsupported,
        field: 'options.presencePenalty',
        message:
            'OpenAI Responses does not support shared presencePenalty; use Chat Completions-compatible models when this knob is required.',
      ),
    );
  }

  if (options.seed != null) {
    warnings.add(
      const ModelWarning(
        type: ModelWarningType.unsupported,
        field: 'options.seed',
        message:
            'OpenAI Responses does not support shared seed; use Chat Completions-compatible models when deterministic sampling is required.',
      ),
    );
  }
}

void applyOpenAIResponsesReasoningCompatibility({
  required OpenAIReasoningEffort? reasoningEffort,
  required Map<String, Object?> body,
  required List<ModelWarning> warnings,
  required bool isReasoningModel,
  required OpenAIModelCapabilities capabilities,
}) {
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
    }

    return;
  }

  if (reasoningEffort != null) {
    warnings.add(
      const ModelWarning(
        type: ModelWarningType.unsupported,
        field: 'reasoningEffort',
        message: 'reasoningEffort is not supported for non-reasoning models',
      ),
    );
  }
}

void applyOpenAIResponsesServiceTierCompatibility({
  required Map<String, Object?> body,
  required List<ModelWarning> warnings,
  required OpenAIModelCapabilities capabilities,
}) {
  final serviceTier = body['service_tier'];
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

List<String>? resolveOpenAIResponsesInclude(
  OpenAIGenerateTextOptions providerOptions, {
  required bool isReasoningModel,
  required bool store,
}) {
  final values = <String>{};

  if (providerOptions.include case final include?) {
    for (final item in include) {
      values.add(item.value);
    }
  }

  if (providerOptions.logprobs != null) {
    values.add(OpenAIResponsesInclude.messageOutputTextLogprobs.value);
  }

  if (!store && isReasoningModel) {
    values.add(OpenAIResponsesInclude.reasoningEncryptedContent.value);
  }

  if (values.isEmpty) {
    return null;
  }

  return values.toList(growable: false);
}

int? encodeOpenAIResponsesTopLogProbs(OpenAILogProbs? logprobs) {
  if (logprobs == null) {
    return null;
  }

  return logprobs.topLogProbs ?? OpenAILogProbs.responsesMaxTopLogProbs;
}
