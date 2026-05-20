import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_generate_text_options.dart';
import 'openai_request_format_codec.dart';
import 'openai_responses_include_options.dart';
import 'openai_responses_openai_compatibility.dart';
import 'openai_responses_request_context.dart';

final class OpenAIResponsesRequestBodyProjection {
  const OpenAIResponsesRequestBodyProjection();

  OpenAIResponsesRequestContext resolveContext({
    required String modelId,
    required OpenAIGenerateTextOptions providerOptions,
  }) {
    return resolveOpenAIResponsesRequestContext(
      modelId: modelId,
      providerOptions: providerOptions,
    );
  }

  Map<String, Object?> encodeBody({
    required String modelId,
    required List<Object?> input,
    required GenerateTextOptions options,
    required OpenAIGenerateTextOptions providerOptions,
    required bool stream,
    required OpenAIResponsesRequestContext context,
    required List<ModelWarning> warnings,
  }) {
    warnConversationConflict(
      providerOptions,
      warnings: warnings,
    );

    final includeOptions = resolveOpenAIResponsesIncludeOptions(
      providerOptions,
      isReasoningModel: context.isReasoningModel,
      store: context.store,
    );
    final effectiveReasoningEffort = resolveReasoningEffort(
      options,
      providerOptions: providerOptions,
      warnings: warnings,
    );
    warnUnsupportedOpenAIResponsesSharedOptions(
      options,
      warnings: warnings,
    );

    final body = <String, Object?>{
      'model': modelId,
      'input': input,
      'stream': stream,
      if (options.maxOutputTokens != null)
        'max_output_tokens': options.maxOutputTokens,
      if (options.temperature != null) 'temperature': options.temperature,
      if (options.stopSequences != null && options.stopSequences!.isNotEmpty)
        'stop': options.stopSequences,
      if (options.topP != null) 'top_p': options.topP,
      if (options.topK != null) 'top_k': options.topK,
      if (providerOptions.previousResponseId != null)
        'previous_response_id': providerOptions.previousResponseId,
      if (providerOptions.conversation != null)
        'conversation': providerOptions.conversation,
      if (providerOptions.store != null) 'store': providerOptions.store,
      if (providerOptions.parallelToolCalls != null)
        'parallel_tool_calls': providerOptions.parallelToolCalls,
      if (providerOptions.serviceTier != null)
        'service_tier': providerOptions.serviceTier,
      if (providerOptions.instructions != null)
        'instructions': providerOptions.instructions,
      if (providerOptions.maxToolCalls != null)
        'max_tool_calls': providerOptions.maxToolCalls,
      if (providerOptions.metadata != null)
        'metadata': providerOptions.metadata,
      if (providerOptions.truncation != null)
        'truncation': providerOptions.truncation!.value,
      if (providerOptions.user != null) 'user': providerOptions.user,
      if (includeOptions.include != null) 'include': includeOptions.include,
      if (providerOptions.promptCacheKey != null)
        'prompt_cache_key': providerOptions.promptCacheKey,
      if (providerOptions.promptCacheRetention != null)
        'prompt_cache_retention': providerOptions.promptCacheRetention!.value,
      if (providerOptions.safetyIdentifier != null)
        'safety_identifier': providerOptions.safetyIdentifier,
      if (includeOptions.topLogProbs != null)
        'top_logprobs': includeOptions.topLogProbs,
      if (context.isReasoningModel && effectiveReasoningEffort != null)
        'reasoning': <String, Object?>{
          'effort': effectiveReasoningEffort.value,
        },
    };

    applyOpenAIResponsesCompatibility(
      reasoningEffort: effectiveReasoningEffort,
      body: body,
      warnings: warnings,
      isReasoningModel: context.isReasoningModel,
      capabilities: context.capabilities,
    );

    if (providerOptions.verbosity != null) {
      body['text'] = <String, Object?>{
        'verbosity': providerOptions.verbosity,
      };
    }

    if (providerOptions.responseFormat case final responseFormat?) {
      body['response_format'] = encodeOpenAIJsonSchemaResponseFormat(
        responseFormat,
      );
    }

    return body;
  }

  void warnConversationConflict(
    OpenAIGenerateTextOptions providerOptions, {
    required List<ModelWarning> warnings,
  }) {
    if (providerOptions.conversation == null ||
        providerOptions.previousResponseId == null) {
      return;
    }

    warnings.add(
      const ModelWarning(
        type: ModelWarningType.unsupported,
        field: 'conversation',
        message: 'conversation and previousResponseId cannot be used together',
      ),
    );
  }

  OpenAIReasoningEffort? resolveReasoningEffort(
    GenerateTextOptions options, {
    required OpenAIGenerateTextOptions providerOptions,
    required List<ModelWarning> warnings,
  }) {
    final sharedReasoningEffort = mapSharedOpenAIReasoningEffort(
      options.reasoning,
      warnings: warnings,
    );

    if (providerOptions.reasoningEffort != null &&
        sharedReasoningEffort != null) {
      warnings.add(
        const ModelWarning(
          type: ModelWarningType.compatibility,
          field: 'options.reasoning',
          message:
              'OpenAI providerOptions.reasoningEffort overrides shared options.reasoning.',
        ),
      );
    }

    return providerOptions.reasoningEffort ?? sharedReasoningEffort;
  }
}
