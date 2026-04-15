part of 'openai_responses_codec.dart';

extension _OpenAIResponsesCodecRequestEncoder on OpenAIResponsesCodec {
  OpenAIResponsesRequest _encodeRequest({
    required String modelId,
    required List<PromptMessage> prompt,
    required List<FunctionToolDefinition> tools,
    required ToolChoice? toolChoice,
    required GenerateTextOptions options,
    required OpenAIGenerateTextOptions providerOptions,
    required bool stream,
  }) {
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
        _encodePromptMessage(
          message,
          warnings,
          systemMessageMode: systemMessageMode,
          store: store,
          hasConversation: hasConversation,
        ),
      );
    }

    final include = _resolveInclude(
      providerOptions,
      isReasoningModel: isReasoningModel,
      store: store,
    );
    final topLogProbs = _encodeResponsesTopLogProbs(providerOptions.logprobs);

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
      if (isReasoningModel && providerOptions.reasoningEffort != null)
        'reasoning': <String, Object?>{
          'effort': providerOptions.reasoningEffort!.value,
        },
    };

    _applyOpenAIReasoningCompatibility(
      providerOptions: providerOptions,
      body: body,
      warnings: warnings,
      isReasoningModel: isReasoningModel,
      capabilities: capabilities,
    );
    _applyOpenAIServiceTierCompatibility(
      body: body,
      warnings: warnings,
      capabilities: capabilities,
    );

    final encodedTools = _encodeTools(
      tools: tools,
      builtInTools: providerOptions.builtInTools,
    );
    if (encodedTools.isNotEmpty) {
      body['tools'] = encodedTools;
      final encodedToolChoice = _encodeToolChoice(
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
      body['response_format'] = _encodeResponseFormat(responseFormat);
    }

    return OpenAIResponsesRequest(
      body: body,
      warnings: warnings,
    );
  }
}
