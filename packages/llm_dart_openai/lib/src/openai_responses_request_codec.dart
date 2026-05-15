import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_model_capabilities.dart';
import 'openai_options.dart';
import 'openai_request_format_codec.dart';
import 'openai_responses_request_options_codec.dart';
import 'openai_responses_request_prompt_codec.dart';
import 'openai_responses_request_tool_codec.dart';

final class OpenAIResponsesRequest {
  final Map<String, Object?> body;
  final List<ModelWarning> warnings;

  OpenAIResponsesRequest({
    required Map<String, Object?> body,
    List<ModelWarning> warnings = const [],
  })  : body = Map.unmodifiable(body),
        warnings = List.unmodifiable(warnings);
}

final class OpenAIResponsesRequestCodec {
  const OpenAIResponsesRequestCodec();

  OpenAIResponsesRequest encodeRequest({
    required String modelId,
    required List<PromptMessage> prompt,
    required List<FunctionToolDefinition> tools,
    required ToolChoice? toolChoice,
    required GenerateTextOptions options,
    required OpenAIGenerateTextOptions providerOptions,
    required bool stream,
  }) {
    const promptCodec = OpenAIResponsesPromptCodec();
    const toolCodec = OpenAIResponsesRequestToolCodec();
    final warnings = <ModelWarning>[];
    final input = <Object?>[];
    final capabilities = getOpenAIModelCapabilities(modelId);
    final isReasoningModel =
        providerOptions.forceReasoning ?? capabilities.isReasoningModel;
    final store = providerOptions.store ?? true;
    final hasConversation = providerOptions.conversation != null;
    final systemMessageMode = providerOptions.systemMessageMode ??
        (isReasoningModel
            ? OpenAISystemMessageMode.developer
            : capabilities.systemMessageMode);

    if (hasConversation && providerOptions.previousResponseId != null) {
      warnings.add(
        const ModelWarning(
          type: ModelWarningType.unsupported,
          field: 'conversation',
          message:
              'conversation and previousResponseId cannot be used together',
        ),
      );
    }

    for (final message in prompt) {
      input.addAll(
        promptCodec.encodePromptMessage(
          message,
          warnings,
          systemMessageMode: systemMessageMode,
          store: store,
          hasConversation: hasConversation,
        ),
      );
    }

    final include = resolveOpenAIResponsesInclude(
      providerOptions,
      isReasoningModel: isReasoningModel,
      store: store,
    );
    final topLogProbs = encodeOpenAIResponsesTopLogProbs(
      providerOptions.logprobs,
    );
    final sharedReasoningEffort = mapSharedOpenAIReasoningEffort(
      options.reasoning,
      warnings: warnings,
    );
    final effectiveReasoningEffort =
        providerOptions.reasoningEffort ?? sharedReasoningEffort;
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
      if (include != null) 'include': include,
      if (providerOptions.promptCacheKey != null)
        'prompt_cache_key': providerOptions.promptCacheKey,
      if (providerOptions.promptCacheRetention != null)
        'prompt_cache_retention': providerOptions.promptCacheRetention!.value,
      if (providerOptions.safetyIdentifier != null)
        'safety_identifier': providerOptions.safetyIdentifier,
      if (topLogProbs != null) 'top_logprobs': topLogProbs,
      if (isReasoningModel && effectiveReasoningEffort != null)
        'reasoning': <String, Object?>{
          'effort': effectiveReasoningEffort.value,
        },
    };

    applyOpenAIResponsesReasoningCompatibility(
      reasoningEffort: effectiveReasoningEffort,
      body: body,
      warnings: warnings,
      isReasoningModel: isReasoningModel,
      capabilities: capabilities,
    );
    applyOpenAIResponsesServiceTierCompatibility(
      body: body,
      warnings: warnings,
      capabilities: capabilities,
    );

    final encodedTools = toolCodec.encodeTools(
      tools: tools,
      builtInTools: providerOptions.builtInTools,
    );
    if (encodedTools.isNotEmpty) {
      body['tools'] = encodedTools;
      final encodedToolChoice = toolCodec.encodeToolChoice(
        toolChoice,
        hasFunctionTools: tools.isNotEmpty,
      );
      if (encodedToolChoice != null) {
        body['tool_choice'] = encodedToolChoice;
      }
    }

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

    return OpenAIResponsesRequest(
      body: body,
      warnings: warnings,
    );
  }
}
